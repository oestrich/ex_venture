defmodule Game.SessionTest do
  use GenServerCase
  use Data.ModelCase

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
    {:noreply, state} = Session.handle_cast({:recv, "name"}, %{socket: socket, active: false, login: nil})

    assert @socket.get_prompts() == [{socket, "Password: "}]
    assert state.login.username == "name"
    assert state.last_recv
  end

  test "recv'ing messages - afterwards", %{socket: socket} do
    create_user(%{username: "user", password: "password"})
    {:ok, other_pid} = Session.start_link(socket)
    GenServer.cast(other_pid, {:recv, "user"})
    GenServer.cast(other_pid, {:recv, "password"})
    wait_cast(other_pid)
    @socket.clear_messages

    {:noreply, state} = Session.handle_cast({:recv, "say hi everyone"}, %{socket: socket, active: true, user: %{username: "name"}})
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

  test "unregisters the pid when disconnected" do
    Registry.register(Session.Registry, "player", :connected)

    {:stop, :normal, _state} = Session.handle_cast(:disconnect, %{})
    assert Registry.lookup(Session.Registry, "player") == []
  end

  test "verifies the user's username and password", %{socket: socket} do
    user = create_user(%{username: "user", password: "password"})

    {:noreply, state} = Session.handle_cast({:recv, "password"}, %{socket: socket, login: %{username: "user"}, active: false})

    assert state.user.id == user.id
    assert state.active == true
    assert @socket.get_echos() == [{socket, "Welcome, user"}]
  end

  test "verifies the user's username and password - failure", %{socket: socket} do
    create_user(%{username: "user", password: "password"})

    {:noreply, state} = Session.handle_cast({:recv, "p@ssword"}, %{socket: socket, login: %{username: "user"}, active: false})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Invalid password"}]
    assert @socket.get_disconnects() == [socket]
  end
end
