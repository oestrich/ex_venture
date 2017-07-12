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
    {:ok, %{socket: pid}}
  end

  def handle_cast({:recv, message}, state = %{socket: pid}) do
    GenServer.cast(pid, {:echo, "Welcome #{message}"})
    {:noreply, state}
  end
end
