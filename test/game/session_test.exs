defmodule Game.SessionTest do
  use GenServerCase

  alias Game.Session

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    {:ok, %{socket: socket}}
  end

  test "echoing messages", %{socket: socket} do
    {:noreply, _state} = Session.handle_cast({:echo, "a message"}, %{socket: socket})

    assert @socket.get_echos() == [{socket, "a message"}]
  end

  test "recv'ing messages - the first", %{socket: socket} do
    {:noreply, state} = Session.handle_cast({:recv, "name"}, %{socket: socket, name: nil})

    assert @socket.get_echos() == [{socket, "Welcome name"}]
    assert state.last_recv
  end

  test "recv'ing messages - afterwards", %{socket: socket} do
    {:ok, other_pid} = Session.start_link(socket)

    {:noreply, state} = Session.handle_cast({:recv, "hi everyone"}, %{socket: socket, name: "name"})
    wait_cast(other_pid)

    assert @socket.get_echos() == [{socket, "\e[34mname\e[0m: hi everyone"}]
    assert state.last_recv
  end

  test "checking for inactive players - not inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now()})

    assert @socket.get_disconnects() == []
  end

  test "checking for inactive players - inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now() |> Timex.shift(minutes: -6)})

    assert @socket.get_disconnects() == [socket]
  end

  test "includes the pid in the registry when starting", %{socket: socket} do
    {:ok, pid} = Session.start_link(socket)

    assert Registry.lookup(Session.Registry, "player") == [{pid, :connected}]
  end

  test "unregisters the pid when disconnected" do
    Registry.register(Session.Registry, "player", :connected)

    {:stop, :normal, _state} = Session.handle_cast(:disconnect, %{})
    assert Registry.lookup(Session.Registry, "player") == []
  end
end
