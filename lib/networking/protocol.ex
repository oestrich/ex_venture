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
  @gmcp 201

  @impl :ranch_protocol
  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  @doc """
  Echo a line to the client

  This includes a new line at the end of the message
  """
  @spec echo(socket :: pid, message :: String.t) :: :ok
  @impl Networking.Socket
  def echo(socket, message) do
    GenServer.cast(socket, {:echo, message})
  end

  @doc """
  Echo a prompt to the client

  This does not include a new line at the end of the message
  """
  @spec prompt(socket :: pid, message :: String.t) :: :ok
  @impl Networking.Socket
  def prompt(socket, message) do
    GenServer.cast(socket, {:echo, message, :prompt})
  end

  @doc """
  Toggle telnet options
  """
  @spec tcp_option(socket :: pid, command :: atom, toggle :: boolean) :: :ok
  @impl Networking.Socket
  def tcp_option(socket, :echo, true) do
    GenServer.cast(socket, {:command, [@iac, @wont, @telnet_option_echo], {:echo, true}})
  end
  def tcp_option(socket, :echo, false) do
    GenServer.cast(socket, {:command, [@iac, @will, @telnet_option_echo], {:echo, false}})
  end

  @doc """
  Push GMCP data to the client
  """
  @spec push_gmcp(socket :: pid, module :: String.t, data :: String.t) :: :ok
  @impl Networking.Socket
  def push_gmcp(socket, module, data) do
    GenServer.cast(socket, {:gmcp, module, data})
  end

  @doc """
  Disconnect the socket

  Will terminate the socket and the session
  """
  @spec disconnect(socket :: pid) :: :ok
  @impl Networking.Socket
  def disconnect(socket) do
    GenServer.cast(socket, :disconnect)
  end

  def init(ref, socket, transport) do
    Logger.info "Player connecting"

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    GenServer.cast(self(), :start_session)
    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport, gmcp: false, gmcp_supports: []})
  end

  @impl GenServer
  def handle_cast({:command, message, _}, state) do
    send_data(state, message)
    {:noreply, state}
  end

  def handle_cast({:gmcp, module, data}, state = %{gmcp: true}) do
    case module in state.gmcp_supports do
      true ->
        Logger.debug ["GMCP: Sending", module]
        module_char = module |> String.to_charlist()
        data_char = data |> String.to_charlist()
        message = [@iac, @sb, @gmcp] ++ module_char ++ data_char ++ [@iac, @se]
        send_data(state, message)
        {:noreply, state}
      false ->
        {:noreply, state}
    end
  end
  def handle_cast({:gmcp, _module, _data}, state) do
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
    send_data(state, [@iac, @will, @gmcp])
    {:noreply, Map.merge(state, %{session: pid})}
  end
  # close the socket and terminate the server
  def handle_cast(:disconnect, state = %{socket: socket, transport: transport}) do
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  @impl GenServer
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

      (:iac) ->
        {:noreply, state}

      (:gmcp) ->
        Logger.info("Will do GCMP")
        {:noreply, Map.put(state, :gmcp, true)}

      ({:gmcp, data}) ->
        data = data |> to_string() |> String.trim()
        Logger.debug(["GMCP: ", data])
        handle_gmcp(data, state)

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

  @doc """
  Handle telnet options

  Multiple IAC dos might come in at the same time, so forward
  them along to us after handling one.
  """
  def handle_options(data, socket, fun) do
    case data do
      << @iac, @telnet_do, @mccp, data :: binary >> ->
        forward_options(socket, data)
        fun.(:mccp)
      << @iac, @telnet_do, @mssp, data :: binary >> ->
        forward_options(socket, data)
        fun.(:mssp)
      << @iac, @telnet_do, @gmcp, data :: binary >> ->
        forward_options(socket, data)
        fun.(:gmcp)
      << @iac, @sb, @gmcp, data :: binary >> ->
        {data, forward} = split_iac_sb(data)
        forward_options(socket, forward)
        fun.({:gmcp, data})
      << @iac, _data :: binary >> ->
        fun.(:iac)
      _ ->
        fun.(:skip)
    end
  end

  @doc """
  Handle GMCP requests

  Handles the following options:
  - Core.Supports.Set
  """
  def handle_gmcp("Core.Supports.Set " <> supports, state) do
    case Poison.decode(supports) do
      {:ok, supports} ->
        supports = remove_version_numbers(supports)
        {:noreply, Map.put(state, :gmcp_supports, supports)}
      _ -> {:noreply, state}
    end
  end
  def handle_gmcp(_, state), do: {:noreply, state}

  defp split_iac_sb(<< @iac, @se, data :: binary >>), do: {[], data}
  defp split_iac_sb(<< int :: size(8), data :: binary >>) do
    {data, forward} = split_iac_sb(data)
    {[int | data], forward}
  end
  defp split_iac_sb(_), do: {[], ""}

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

  defp remove_version_numbers(supports) do
    supports
    |> Enum.map(fn (support) ->
      support |> String.split(" ") |> List.first()
    end)
  end
end
