defmodule Networking.Protocol do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  @doc """
  Echo a line to the client

  This includes a new line at the end of the message
  """
  @spec echo(socket :: pid, message :: String.t) :: :ok
  def echo(socket, message) do
    GenServer.cast(socket, {:echo, message})
  end

  @doc """
  Echo a prompt to the client

  This does not include a new line at the end of the message
  """
  @spec prompt(socket :: pid, message :: String.t) :: :ok
  def prompt(socket, message) do
    GenServer.cast(socket, {:echo, message, :prompt})
  end

  @doc """
  Disconnect the socket

  Will terminate the socket and the session
  """
  @spec disconnect(socket :: pid) :: :ok
  def disconnect(socket) do
    GenServer.cast(socket, :disconnect)
  end

  def init(ref, socket, transport) do
    Logger.info "Player connecting"

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    GenServer.cast(self(), :start_session)
    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
  end

  def handle_cast({:echo, message}, state = %{socket: socket, transport: transport}) do
    transport.send(socket, "#{message}\n")
    {:noreply, state}
  end
  def handle_cast({:echo, message, :prompt}, state = %{socket: socket, transport: transport}) do
    transport.send(socket, message)
    {:noreply, state}
  end
  def handle_cast(:start_session, state) do
    {:ok, pid} = Game.Session.start(self())
    {:noreply, Map.merge(state, %{session: pid})}
  end
  # close the socket and terminate the server
  def handle_cast(:disconnect, state = %{socket: socket, transport: transport}) do
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  def handle_info({:tcp, socket, data}, state = %{socket: socket, transport: transport}) do
    case state do
      %{session: pid} ->
        pid |> Game.Session.recv(data |> String.trim)
      _ ->
        transport.send(socket, data)
    end
    {:noreply, state}
  end
  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    Logger.info "Closing"
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end
  def handle_info({:tcp_error, _socket, :etimedout}, state = %{socket: socket, transport: transport}) do
    Logger.info "Timeout"
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  # Disconnect the socket and optionally the session
  defp disconnect(transport, socket, state) do
    case state do
      %{session: pid} -> pid |> Game.Session.disconnect()
      _ -> nil
    end
    transport.close(socket)
  end
end
