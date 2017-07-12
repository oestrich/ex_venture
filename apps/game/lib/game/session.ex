defmodule Game.Session do
  use GenServer

  def start(pid) do
    GenServer.cast(pid, {:echo, "Welcome to ExMud\n"})
    GenServer.cast(pid, {:echo, "What is your player name? "})

    Game.Session.Supervisor.start_child(pid)
  end

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  def init(pid) do
    {:ok, %{socket: pid, name: nil}}
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
    Supervisor.which_children(Game.Session.Supervisor)
    |> Enum.each(fn ({_, pid, _, _}) ->
      GenServer.cast(pid, {:echo, "#{name}: #{message}\n"})
    end)
    {:noreply, state}
  end
end
