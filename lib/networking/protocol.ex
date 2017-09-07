defmodule Networking.Protocol do
  @moduledoc """
  Ranch protocol implementation, socket genserver
  """

  use GenServer
  require Logger

  alias Game.Color
  alias Networking.MSSP

  @behaviour :ranch_protocol
  @behaviour Networking.Socket

  @iac 255
  @will 251
  @wont 252
  @telnet_do 253
  @sb 250
  @se 240
  @telnet_option_echo 1

  @mccp 86
  @mssp 70

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
  Toggle telnet options
  """
  @spec tcp_option(socket :: pid, command :: atom, toggle :: boolean) :: :ok
  def tcp_option(socket, :echo, true) do
    GenServer.cast(socket, {:command, [@iac, @wont, @telnet_option_echo], {:echo, true}})
  end
  def tcp_option(socket, :echo, false) do
    GenServer.cast(socket, {:command, [@iac, @will, @telnet_option_echo], {:echo, false}})
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

  def handle_cast({:command, message, _}, state) do
    send_data(state, message)
    {:noreply, state}
  end
  def handle_cast({:echo, message}, state) do
    send_data(state, "\n#{message |> Color.format}\n")
    {:noreply, state}
  end
  def handle_cast({:echo, message, :prompt}, state) do
    send_data(state, "\n#{message |> Color.format}")
    {:noreply, state}
  end
  def handle_cast(:start_session, state) do
    {:ok, pid} = Game.Session.start(self())
    send_data(state, [@iac, @will, @mccp])
    send_data(state, [@iac, @will, @mssp])
    {:noreply, Map.merge(state, %{session: pid})}
  end
  # close the socket and terminate the server
  def handle_cast(:disconnect, state = %{socket: socket, transport: transport}) do
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  def handle_info({:tcp, socket, data}, state) do
    handle_options(data, socket, fn
      (:mccp) ->
        Logger.info("Starting MCCP")
        zlib_context = :zlib.open()
        :zlib.deflateInit(zlib_context, 9)
        send_data(state, [@iac, @sb, @mccp, @iac, @se])

        {:noreply, Map.put(state, :zlib_context, zlib_context)}

      (:mssp) ->
        Logger.info("Sending MSSP")

        send_data(state, [@iac, @sb] ++ MSSP.name() ++ MSSP.players() ++ MSSP.uptime() ++ [@iac, @se])

        {:noreply, state}

      (:iac) -> {:noreply, state}

      (_) ->
        case state do
          %{session: pid} ->
            pid |> Game.Session.recv(data |> String.trim)
          _ ->
            send_data(state, data)
        end

        {:noreply, state}
    end)
  end
  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    Logger.info "Connection Closed"
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end
  def handle_info({:tcp_error, _socket, :etimedout}, state = %{socket: socket, transport: transport}) do
    Logger.info "Connection Timeout"
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  # Disconnect the socket and optionally the session
  defp disconnect(transport, socket, state) do
    terminate_zlib_context(state)
    case state do
      %{session: pid} ->
        Logger.info "Disconnecting player"
        pid |> Game.Session.disconnect()
      _ -> nil
    end
    transport.close(socket)
  end

  # multiple IAC dos might come in at the same time, so forward
  # them along to us after handling one
  defp handle_options(data, socket, fun) do
    case data do
      << @iac, @telnet_do, @mccp, data :: binary >> ->
        forward_options(socket, data)
        fun.(:mccp)
      << @iac, @telnet_do, @mssp, data :: binary >> ->
        forward_options(socket, data)
        fun.(:mssp)
      << @iac, _data :: binary >> -> fun.(:iac)
      _ -> fun.(:skip)
    end
  end

  defp forward_options(_socket, ""), do: nil
  defp forward_options(socket, data) do
    send(self(), {:tcp, socket, data})
  end

  defp terminate_zlib_context(%{zlib_context: nil}), do: nil
  defp terminate_zlib_context(%{zlib_context: zlib_context}) do
    Logger.info "Terminating zlib stream"
    :zlib.deflate(zlib_context, "", :finish)
    :zlib.deflateEnd(zlib_context)
  end
  defp terminate_zlib_context(_), do: nil

  defp send_data(%{socket: socket, transport: transport, zlib_context: zlib_context}, data) do
    data = :zlib.deflate(zlib_context, data, :full)
    transport.send(socket, data)
  end
  defp send_data(%{socket: socket, transport: transport}, data) do
    transport.send(socket, data)
  end
end
