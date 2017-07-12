defmodule Game.Session do
  use GenServer

  alias Game.Session

  def start(pid) do
    GenServer.cast(pid, {:echo, "Welcome to ExMud\n"})
    GenServer.cast(pid, {:echo, "What is your player name? "})

    Session.Supervisor.start_child(pid)
  end

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  def disconnect(pid) do
    GenServer.cast(pid, :disconnect)
  end

  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  def init(pid) do
    Registry.register(Session.Registry, "player", :connected)
    {:ok, %{socket: pid, name: nil}}
  end

  def handle_cast(:disconnect, state) do
    Registry.unregister(Session.Registry, "player")
    {:stop, :normal, state}
  end

  # forward the echo the socket pid
  def handle_cast({:echo, message}, state = %{socket: socket}) do
    GenServer.cast(socket, {:echo, message})
    {:noreply, state}
  end
  def handle_cast({:recv, name}, state = %{socket: socket, name: nil}) do
    GenServer.cast(socket, {:echo, "Welcome #{name}\n"})
    {:noreply, Map.merge(state, %{name: name})}
  end
  def handle_cast({:recv, message}, state = %{name: name}) do
    Session.Registry
    |> Registry.lookup("player")
    |> Enum.each(fn ({pid, _}) ->
      GenServer.cast(pid, {:echo, "#{name}: #{message}\n"})
    end)

    {:noreply, state}
  end
end
