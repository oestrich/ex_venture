defmodule Game.Session do
  use GenServer
  require Logger

  alias Game.Authentication
  alias Game.Color
  alias Game.Session

  @socket Application.get_env(:ex_mud, :networking)[:socket_module]

  @timeout_check 5000
  @timeout_seconds 5 * 60 * -1
  @registry_key "player"

  @doc """
  Start a new session

  Creates a session pointing at a socket
  """
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

  #
  # GenServer callbacks
  #

  def init(socket) do
    socket |> @socket.echo("Welcome to ExMud")
    socket |> @socket.prompt("What is your player name? ")

    Registry.register(Session.Registry, @registry_key, :connected)
    self() |> schedule_inactive_check()
    {:ok, %{socket: socket, active: false, name: nil, last_recv: Timex.now()}}
  end

  # On a disconnect unregister the PID and stop the server
  def handle_cast(:disconnect, state) do
    Registry.unregister(Session.Registry, @registry_key)
    {:stop, :normal, state}
  end

  # forward the echo the socket pid
  def handle_cast({:echo, message}, state = %{socket: socket}) do
    socket |> @socket.echo(message)
    {:noreply, state}
  end

  # The first receive should ask for the name
  def handle_cast({:recv, name}, state = %{socket: socket, name: nil}) do
    socket |> @socket.prompt("Password: ")
    {:noreply, Map.merge(state, %{name: name, last_recv: Timex.now()})}
  end
  def handle_cast({:recv, password}, state = %{socket: socket, name: name, active: false}) do
    case Authentication.find_and_validate(name, password) do
      {:error, :invalid} ->
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        {:noreply, state}
      user ->
        socket |> @socket.echo("Welcome, #{user.username}")
        {:noreply, Map.merge(state, %{user: user, active: true})}
    end
  end
  # Receives afterwards should forward the message to the other clients
  def handle_cast({:recv, message}, state = %{active: true, name: name}) do
    Session.Registry
    |> Registry.lookup(@registry_key)
    |> Enum.each(fn ({pid, _}) ->
      GenServer.cast(pid, {:echo, Color.format("{blue}#{name}{/blue}: #{message}")})
    end)

    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  def handle_info(:inactive_check, state) do
    state |> check_for_inactive()
    {:noreply, state}
  end

  # Schedule an inactive check
  defp schedule_inactive_check(pid) do
    :erlang.send_after(@timeout_check, pid, :inactive_check)
  end

  # Check if the session is inactive, disconnect if it is
  defp check_for_inactive(%{socket: socket, last_recv: last_recv}) do
    case Timex.diff(last_recv, Timex.now, :seconds) do
      time when time < @timeout_seconds ->
        Logger.info "Disconnecting player"
        socket |> @socket.disconnect()
      _ ->
        self() |> schedule_inactive_check()
    end
  end
end
