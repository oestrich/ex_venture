defmodule Game.Session do
  @moduledoc """
  GenServer connected to the socket

  Holds knowledge if the user is logged in, who they are, what they're save is.
  """

  @type t :: pid

  use GenServer
  use Networking.Socket
  use Game.Room

  require Logger

  import Game.Character.Helpers, only: [clear_target: 2]

  alias Game.Account
  alias Game.Character
  alias Game.Command
  alias Game.Command.Move
  alias Game.Command.Pager
  alias Game.Experience
  alias Game.Format
  alias Game.Session
  alias Game.Session.Effects
  alias Game.Session.GMCP
  alias Game.Session.Tick
  alias Metrics.PlayerInstrumenter

  @save_period 15_000
  @force_disconnect_period 5_000

  @timeout_check 5000
  @timeout_seconds Application.get_env(:ex_venture, :game)[:timeout_seconds]

  defmodule State do
    @moduledoc """
    Create a struct for Session state
    """

    @enforce_keys [:socket, :state, :mode]
    defstruct [:socket, :state, :session_started_at, :last_recv, :last_tick, :mode, :target, :is_targeting, :regen, :reply_to]
  end

  @doc """
  Start a new session

  Creates a session pointing at a socket
  """
  @spec start(socket_pid :: pid) :: {:ok, pid}
  def start(socket) do
    Session.Supervisor.start_child(socket)
  end

  @doc false
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @doc """
  Send a disconnect signal to a session
  """
  @spec disconnect(pid) :: :ok
  def disconnect(pid) do
    GenServer.cast(pid, :disconnect)
  end
  @spec disconnect(pid, opts :: Keyword.t) :: :ok
  def disconnect(pid, opts) do
    GenServer.cast(pid, {:disconnect, opts})
  end

  @doc """
  Send a recv signal from the socket
  """
  @spec recv(pid, message :: String.t) :: :ok
  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  @doc """
  Echo to the socket
  """
  @spec echo(pid, message :: String.t) :: :ok
  def echo(pid, message) do
    GenServer.cast(pid, {:echo, message})
  end

  @doc """
  Send a tick to the session
  """
  @spec tick(pid, time :: DateTime.t) :: :ok
  def tick(pid, time) do
    GenServer.cast(pid, {:tick, time})
  end

  @doc """
  Notify the session of an event, e.g. someone left the room
  """
  @spec notify(pid, action :: tuple()) :: :ok
  def notify(pid, action) do
    GenServer.cast(pid, {:notify, action})
  end

  @doc """
  Teleport the user to the room passed in
  """
  @spec teleport(pid, room_id :: integer) :: :ok
  def teleport(pid, room_id) do
    GenServer.cast(pid, {:teleport, room_id})
  end

  def sign_in(pid, user) do
    GenServer.cast(pid, {:sign_in, user.id})
  end

  #
  # GenServer callbacks
  #

  def init(socket) do
    socket |> Session.Login.start()
    self() |> schedule_save()
    self() |> schedule_inactive_check()
    last_tick = Timex.now() |> Timex.shift(minutes: -2)

    Logger.info("New session started #{inspect(self())}", type: :session)
    PlayerInstrumenter.session_started()

    state = %State{
      socket: socket,
      state: "login",
      session_started_at: Timex.now(),
      last_recv: Timex.now(),
      last_tick: last_tick,
      mode: "commands",
      target: nil,
      is_targeting: MapSet.new,
      regen: %{count: 0},
      reply_to: nil,
    }

    {:ok, state}
  end

  # On a disconnect unregister the PID and stop the server
  def handle_cast(:disconnect, state = %{state: "login"}) do
    {:stop, :normal, state}
  end
  def handle_cast(:disconnect, state = %{state: "create"}) do
    {:stop, :normal, state}
  end
  def handle_cast(:disconnect, state = %{user: user, save: save, session_started_at: session_started_at}) do
    Session.Registry.unregister()
    @room.leave(save.room_id, {:user, self(), user})
    clear_target(state, {:user, user})
    user |> Account.save(save)
    user |> Account.update_time_online(session_started_at, Timex.now())
    {:stop, :normal, state}
  end

  def handle_cast({:disconnect, [force: true]}, state = %{socket: socket}) do
    socket |> @socket.echo("The server will be shutting down shortly.")
    Task.start(fn () ->
      Process.sleep(@force_disconnect_period)
      socket |> @socket.disconnect()
    end)
    {:noreply, state}
  end

  # forward the echo the socket pid
  def handle_cast({:echo, message}, state = %{socket: socket}) do
    socket |> @socket.echo(message)
    {:noreply, state}
  end

  # Update the tick timestamp
  def handle_cast({:tick, time}, state = %{save: _save}) do
    {:noreply, Tick.tick(time, state)}
  end

  # Handle logging in
  def handle_cast({:recv, name}, state = %{state: "login"}) do
    state = Session.Login.process(name, self(), state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Handle creating an account
  def handle_cast({:recv, name}, state = %{state: "create"}) do
    state = Session.CreateAccount.process(name, self(), state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Receives afterwards should forward the message to the other clients
  def handle_cast({:recv, message}, state = %{state: "active", mode: "commands", user: user}) do
    state = Map.merge(state, %{last_recv: Timex.now()})
    message |> Command.parse(user) |> run_command(self(), state)
  end
  def handle_cast({:recv, message}, state = %{state: "active", mode: "paginate"}) do
    {:noreply, Pager.paginate(state, command: message)}
  end
  def handle_cast({:recv, _message}, state = %{state: "active", mode: "continuing"}) do
    {:noreply, state}
  end

  def handle_cast({:recv, ""}, state = %{state: "active", mode: "editor"}) do
    case state.editor_module.editor(:complete, state) do
      {:update, state} ->
        state =
          state
          |> Map.put(:mode, "commands")
          |> Map.delete(:editor_module)

        state |> prompt()
        {:noreply, Map.put(state, :mode, "commands")}
    end
  end
  def handle_cast({:recv, line}, state = %{state: "active", mode: "editor"}) do
    case state.editor_module.editor({:text, line}, state) do
      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:teleport, room_id}, state) do
    {:update, state} = self() |> Move.move_to(state, room_id)
    state |> prompt()
    {:noreply, state}
  end

  # Handle logging in from the web client
  def handle_cast({:sign_in, user_id}, state = %{state: "login"}) do
    state = Session.Login.sign_in(user_id, self(), state)
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, player}, state = %{socket: socket}) do
    socket |> @socket.echo("You are being targeted by #{Format.name(player)}.")

    state =
      state
      |> maybe_target(player)
      |> Map.put(:is_targeting, MapSet.put(state.is_targeting, Character.who(player)))

    {:noreply, state}
  end

  def handle_cast({:remove_target, character}, state) do
    echo(self(), "You are no longer being targeted by #{Format.name(character)}.")
    state = Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Character.who(character)))
    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, description}, state = %{state: "active"}) do
    state = Effects.apply(effects, from, description, state)
    state |> GMCP.vitals()
    {:noreply, state}
  end

  def handle_cast({:notify, {"room/entered", character}}, state) do
    echo(self(), "#{Format.name(character)} enters")
    state |> GMCP.character_enter(character)
    {:noreply, state}
  end
  def handle_cast({:notify, {"room/leave", character}}, state) do
    echo(self(), "#{Format.name(character)} leaves")
    state |> GMCP.character_leave(character)

    target = Map.get(state, :target, nil)
    case Character.who(character) do
      ^target -> {:noreply, %{state | target: nil}}
      _ -> {:noreply, state}
    end
  end
  # generic fall through case
  def handle_cast({:notify, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:died, who}, state = %{state: "active", target: target}) when is_nil(target) do
    echo(self(), "#{Format.target_name(who)} has died.")
    {:noreply, state}
  end
  def handle_cast({:died, who}, state = %{socket: socket, state: "active", user: user, target: target}) do
    socket |> @socket.echo("#{Format.target_name(who)} has died.")
    state = apply_experience(state, who)
    state |> prompt()

    case Character.who(target) == Character.who(who) do
      true ->
        Character.remove_target(target, {:user, user})

        state =
          state
          |> Map.put(:target, nil)
          |> maybe_target(possible_new_target(state, target))

        {:noreply, state}
      false -> {:noreply, state}
    end
  end

  @doc """
  Get a possible new target from the list
  """
  @spec possible_new_target(state :: map, target :: {atom(), integer()}) :: {atom(), map()}
  def possible_new_target(state, target) do
    state.is_targeting
    |> MapSet.delete(Character.who(target))
    |> MapSet.to_list()
    |> List.first()
    |> character_info()
  end

  @doc """
  Get a character's information, handles nil
  """
  def character_info(nil), do: nil
  def character_info(player), do: Character.info(player)

  @doc """
  Maybe target the character who targeted you, only if your own target is empty
  """
  @spec maybe_target(state :: map, player :: {atom(), integer()} | {atom(), map()} | nil) :: map
  def maybe_target(state, player)
  def maybe_target(state, nil), do: state
  def maybe_target(state = %{socket: socket, target: nil, user: user}, player) do
    socket |> @socket.echo("You are now targeting #{Format.name(player)}.")
    player = Character.who(player)
    Character.being_targeted(player, {:user, user})
    Map.put(state, :target, player)
  end
  def maybe_target(state, _player), do: state

  defp apply_experience(state, {:user, _user}), do: state
  defp apply_experience(state, {:npc, npc}) do
    Experience.apply(state, level: npc.level, experience_points: npc.experience_points)
  end

  def handle_call(:info, _from, state) do
    {:reply, {:user, state.user}, state}
  end

  #
  # Channels
  #

  def handle_info({:channel, {:joined, channel}}, state = %{save: save}) do
    channels = [channel | save.channels]
    |> Enum.into(MapSet.new)
    |> Enum.into([])

    save = %{save | channels: channels}
    state = %{state | save: save}
    {:noreply, state}
  end

  def handle_info({:channel, {:left, channel}}, state = %{save: save}) do
    channels = Enum.reject(save.channels, &(&1 == channel))
    save = %{save | channels: channels}
    state = %{state | save: save}
    {:noreply, state}
  end

  def handle_info({:channel, {:broadcast, message}}, state = %{socket: socket}) do
    socket |> @socket.echo(message)
    {:noreply, state}
  end

  def handle_info({:channel, {:tell, from, message}}, state = %{socket: socket}) do
    socket |> @socket.echo(message)
    {:noreply, Map.put(state, :reply_to, from)}
  end

  #
  # General callback
  #

  def handle_info({:continue, command}, state) do
    command |> run_command(self(), state)
  end

  def handle_info(:save, state = %{user: user, save: save, session_started_at: session_started_at}) do
    user |> Account.save(save)
    user |> Account.update_time_online(session_started_at, Timex.now())
    self() |> schedule_save()
    {:noreply, state}
  end
  def handle_info(:save, state) do
    self() |> schedule_save()
    {:noreply, state}
  end

  def handle_info(:inactive_check, state) do
    state |> check_for_inactive()
    {:noreply, state}
  end

  def run_command(command, session, state) do
    case command |> Command.run(session, state) do
      {:update, state} ->
        Session.Registry.update(%{state.user | save: state.save})
        state |> prompt()
        {:noreply, Map.put(state, :mode, "commands")}
      {:update, state, {command = %Command{}, send_in}} ->
        Session.Registry.update(%{state.user | save: state.save})
        :erlang.send_after(send_in, self(), {:continue, command})
        {:noreply, Map.put(state, :mode, "continuing")}
      {:paginate, text, state} ->
        state =
          state
          |> Map.put(:pagination, %{text: text})

        {:noreply, Pager.paginate(state)}
      {:editor, module, state} ->
        state =
          state
          |> Map.put(:mode, "editor")
          |> Map.put(:editor_module, module)

        {:noreply, state}
      _ ->
        state |> prompt()
        {:noreply, Map.put(state, :mode, "commands")}
    end
  end

  @doc """
  Send the prompt to the user's socket
  """
  def prompt(state = %{socket: socket, user: user, save: save}) do
    state |> GMCP.vitals()
    socket |> @socket.prompt(Format.prompt(user, save))
  end

  # Schedule an inactive check
  defp schedule_inactive_check(pid) do
    :erlang.send_after(@timeout_check, pid, :inactive_check)
  end

  # Schedule a save
  defp schedule_save(pid) do
    :erlang.send_after(@save_period, pid, :save)
  end

  # Check if the session is inactive, disconnect if it is
  defp check_for_inactive(%{socket: socket, last_recv: last_recv}) do
    case Timex.diff(Timex.now, last_recv, :seconds) do
      time when time > @timeout_seconds ->
        Logger.info("Idle player #{inspect(self())} - disconnecting", type: :session)
        socket |> @socket.disconnect()
      _ ->
        self() |> schedule_inactive_check()
    end
  end
end
