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

  import Game.Character.Target, only: [clear_target: 2]

  alias Game.Account
  alias Game.Character
  alias Game.Command
  alias Game.Experience
  alias Game.Format
  alias Game.Session
  alias Game.Session.Effects
  alias Game.Session.Tick

  @save_period 15_000

  @timeout_check 5000
  @timeout_seconds 5 * 60 * -1

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

  #
  # GenServer callbacks
  #

  def init(socket) do
    socket |> Session.Login.start()
    self() |> schedule_save()
    self() |> schedule_inactive_check()
    last_tick = Timex.now() |> Timex.shift(minutes: -2)

    state = %{
      socket: socket,
      state: "login",
      last_move: Timex.now(),
      last_recv: Timex.now(),
      last_tick: last_tick,
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
  def handle_cast(:disconnect, state = %{user: user, save: save}) do
    Session.Registry.unregister()
    @room.leave(save.room_id, {:user, self(), user})
    clear_target(state, {:user, user})
    user |> Account.save(save)
    {:stop, :normal, state}
  end

  # forward the echo the socket pid
  def handle_cast({:echo, message}, state = %{socket: socket}) do
    socket |> @socket.echo(message)
    state |> prompt()
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
  def handle_cast({:recv, message}, state = %{state: "active", user: user}) do
    state = Map.merge(state, %{last_recv: Timex.now()})
    case message |> Command.parse(user) |> Command.run(self(), state) do
      :ok ->
        state |> prompt()
        {:noreply, state}
      {:update, state} ->
        state |> prompt()
        {:noreply, state}
    end
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, {_, player}}, state) do
    echo(self(), "You are being targeted by {blue}#{player.name}{/blue}.")
    state = Map.put(state, :is_targeting, MapSet.put(state.is_targeting, {:user, player.id}))
    {:noreply, state}
  end

  def handle_cast({:remove_target, player}, state) do
    echo(self(), "You are no longer being targeted by {blue}#{elem(player, 1).name}{/blue}.")
    state = Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Game.Character.who(player)))
    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, description}, state = %{state: "active"}) do
    state = Effects.apply(effects, from, description, state)
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
        {:noreply, Map.put(state, :target, nil)}
      false -> {:noreply, state}
    end
  end

  defp apply_experience(state, {:user, _user}), do: state
  defp apply_experience(state, {:npc, npc}) do
    Experience.apply(state, level: npc.level, experience_points: npc.experience_points)
  end

  #
  # Channels
  #

  def handle_info({:channel, {:joined, channel}}, state = %{save: save}) do
    save = %{save | channels: [channel | save.channels]}
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

  def handle_info(:save, state = %{user: user, save: save}) do
    user |> Account.save(save)
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

  defp prompt(%{socket: socket, user: user, save: save}) do
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
    case Timex.diff(last_recv, Timex.now, :seconds) do
      time when time < @timeout_seconds ->
        Logger.info "Idle player - disconnecting"
        socket |> @socket.disconnect()
      _ ->
        self() |> schedule_inactive_check()
    end
  end
end
