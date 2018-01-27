defmodule Game.Session.Process do
  @moduledoc """
  GenServer process module, client access is at `Game.Session`

  Holds knowledge if the user is logged in, who they are, what they're save is.
  """

  use GenServer
  use Networking.Socket
  use Game.Room

  require Logger

  import Game.Character.Helpers, only: [clear_target: 2]

  alias Game.Account
  alias Game.Command.Move
  alias Game.Command.Pager
  alias Game.Format
  alias Game.Session
  alias Game.Session.Channels
  alias Game.Session.Character, as: SessionCharacter
  alias Game.Session.Commands
  alias Game.Session.Effects
  alias Game.Session.GMCP
  alias Game.Session.Regen
  alias Game.Session.SessionStats
  alias Game.Session.State
  alias Metrics.PlayerInstrumenter

  @save_period 15_000
  @force_disconnect_period 5_000

  @timeout_check 5000
  @timeout_seconds Application.get_env(:ex_venture, :game)[:timeout_seconds]

  #
  # GenServer callbacks
  #

  @doc false
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    socket |> Session.Login.start()
    self() |> schedule_save()
    self() |> schedule_inactive_check()

    Logger.info("New session started #{inspect(self())}", type: :session)
    PlayerInstrumenter.session_started()

    state = %State{
      socket: socket,
      state: "login",
      session_started_at: Timex.now(),
      last_recv: Timex.now(),
      mode: "commands",
      target: nil,
      is_targeting: MapSet.new(),
      regen: %{is_regenerating: false, count: 0},
      reply_to: nil,
      commands: %{},
      stats: %SessionStats{}
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

  def handle_cast(:disconnect, state = %{state: "active"}) do
    %{user: user, save: save, session_started_at: session_started_at, stats: stats} = state
    Session.Registry.unregister()
    @room.leave(save.room_id, {:user, user})
    clear_target(state, {:user, user})
    user |> Account.save_session(save, session_started_at, Timex.now(), stats)
    {:stop, :normal, state}
  end

  def handle_cast({:disconnect, [force: true]}, state = %{socket: socket}) do
    socket |> @socket.echo("The server will be shutting down shortly.")

    Task.start(fn ->
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

  # Handle logging in
  def handle_cast({:recv, name}, state = %{state: "login"}) do
    state = Session.Login.process(name, state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Handle displaying message after signing in
  def handle_cast({:recv, _name}, state = %{state: "after_sign_in"}) do
    state = Session.Login.after_sign_in(state, self())
    send(self(), :regen)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Handle creating an account
  def handle_cast({:recv, name}, state = %{state: "create"}) do
    state = Session.CreateAccount.process(name, state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  def handle_cast({:recv, message}, state = %{state: "active", mode: "commands"}) do
    state |> Commands.process_command(message)
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
    {:update, state} = Move.move_to(state, room_id)
    state |> prompt()
    {:noreply, state}
  end

  # Handle logging in from the web client
  def handle_cast({:sign_in, user_id}, state = %{state: "login"}) do
    state = Session.Login.sign_in(user_id, state)
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, player}, state) do
    {:noreply, SessionCharacter.targeted(state, player)}
  end

  def handle_cast({:remove_target, character}, state) do
    {:noreply, SessionCharacter.remove_target(state, character)}
  end

  def handle_cast({:apply_effects, effects, from, description}, state = %{state: "active"}) do
    {:noreply, SessionCharacter.apply_effects(state, effects, from, description)}
  end

  def handle_cast({:notify, event}, state) do
    {:noreply, SessionCharacter.notify(state, event)}
  end

  def handle_cast({:died, who}, state = %{state: "active"}) do
    {:noreply, SessionCharacter.died(state, who)}
  end

  def handle_call(:info, _from, state) do
    {:reply, {:user, state.user}, state}
  end

  #
  # Channels
  #

  def handle_info({:channel, {:joined, channel}}, state) do
    {:noreply, Channels.joined(state, channel)}
  end

  def handle_info({:channel, {:left, channel}}, state) do
    {:noreply, Channels.left(state, channel)}
  end

  def handle_info({:channel, {:broadcast, channel, message}}, state) do
    {:noreply, Channels.broadcast(state, channel, message)}
  end

  def handle_info({:channel, {:tell, from, message}}, state) do
    {:noreply, Channels.tell(state, from, message)}
  end

  #
  # General callback
  #

  def handle_info(:regen, state = %{save: _save}) do
    {:noreply, Regen.tick(state)}
  end

  def handle_info({:continue, command}, state) do
    command |> Commands.run_command(state)
  end

  def handle_info(:save, state = %{state: "active"}) do
    %{user: user, save: save, session_started_at: session_started_at} = state
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

  def handle_info({:continuous_effect, effect_id}, state) do
    state = Effects.handle_continuous_effect(state, effect_id)
    state |> prompt()
    {:noreply, state}
  end

  def handle_info(:resurrect, state) do
    %{save: %{stats: stats}} = state

    case stats.health do
      health when health < 1 ->
        stats = Map.put(stats, :health, 1)
        save = Map.put(state.save, :stats, stats)
        user = Map.put(state.user, :save, save)

        state =
          state
          |> Map.put(:save, save)
          |> Map.put(:user, user)

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  @doc """
  Send the prompt to the user's socket
  """
  def prompt(state = %{socket: socket, user: user, save: save}) do
    state |> GMCP.vitals()
    socket |> @socket.prompt(Format.prompt(user, save))
    state
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
    case Timex.diff(Timex.now(), last_recv, :seconds) do
      time when time > @timeout_seconds ->
        Logger.info("Idle player #{inspect(self())} - disconnecting", type: :session)
        socket |> @socket.disconnect()

      _ ->
        self() |> schedule_inactive_check()
    end
  end
end
