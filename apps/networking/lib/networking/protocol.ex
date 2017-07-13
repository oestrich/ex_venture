defmodule Networking.Protocol do
  use GenServer

  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(ref, socket, transport) do
    IO.puts "Player connecting"

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    GenServer.cast(self(), :start_session)
    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
  end

  def handle_cast({:echo, message}, state = %{socket: socket, transport: transport}) do
    transport.send(socket, message)
    {:noreply, state}
  end
  def handle_cast(:start_session, state) do
    {:ok, pid} = Game.Session.start(self())
    {:noreply, Map.merge(state, %{session: pid})}
  end

  def handle_info({:tcp, socket, data}, state = %{socket: socket, transport: transport}) do
    case state do
      %{session: pid} ->
        Game.Session.recv(pid, data |> String.trim)
      _ ->
        transport.send(socket, data)
    end
    {:noreply, state}
  end
  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    IO.puts "Closing"
    case state do
      %{session: pid} ->
        Game.Session.disconnect(pid)
      _ -> nil
    end
    transport.close(socket)
    {:stop, :normal, state}
  end
  def handle_info({:tcp_error, _socket, :etimedout}, state) do
    IO.puts "Timeout"
    case state do
      %{session: pid} ->
        Game.Session.disconnect(pid)
      _ -> nil
    end
    {:stop, :normal, state}
  end
end
