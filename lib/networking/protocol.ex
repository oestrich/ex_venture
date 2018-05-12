defmodule Networking.Protocol do
  @moduledoc """
  Ranch protocol implementation, socket genserver
  """

  use GenServer
  require Logger

  alias Game.Color
  alias Metrics.PlayerInstrumenter
  alias Networking.MSSP
  alias Web.Endpoint
  alias Web.Router.Helpers, as: RoutesHelper

  @mudlet_version 4

  @behaviour :ranch_protocol
  @behaviour Networking.Socket

  @iac 255
  @will 251
  @wont 252
  @telnet_do 253
  @telnet_dont 254
  @sb 250
  @se 240
  @telnet_option_echo 1
  @ga 249

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
  @spec echo(pid, String.t()) :: :ok
  @impl Networking.Socket
  def echo(socket, message) do
    GenServer.cast(socket, {:echo, message})
  end

  @doc """
  Echo a prompt to the client

  This does not include a new line at the end of the message
  """
  @spec prompt(pid, String.t()) :: :ok
  @impl Networking.Socket
  def prompt(socket, message) do
    GenServer.cast(socket, {:echo, message, :prompt})
  end

  @doc """
  Toggle telnet options
  """
  @spec tcp_option(pid, atom, boolean) :: :ok
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
  @spec push_gmcp(pid, String.t(), String.t()) :: :ok
  @impl Networking.Socket
  def push_gmcp(socket, module, data) do
    Logger.debug(fn ->
      "Pushing GMCP #{module} - #{data}"
    end)
    GenServer.cast(socket, {:gmcp, module, data})
  end

  @doc """
  Disconnect the socket

  Will terminate the socket and the session
  """
  @spec disconnect(pid) :: :ok
  @impl Networking.Socket
  def disconnect(socket) do
    GenServer.cast(socket, :disconnect)
  end

  @doc """
  Set the user id of the socket
  """
  @spec set_user_id(pid, integer()) :: :ok
  @impl Networking.Socket
  def set_user_id(socket, user_id) do
    GenServer.cast(socket, {:user_id, user_id})
  end

  @impl Networking.Socket
  def set_config(socket, config) do
    GenServer.cast(socket, {:config, config})
  end

  def init(ref, socket, transport) do
    Logger.info("Player connecting", type: :socket)
    PlayerInstrumenter.session_started(:telnet)

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    GenServer.cast(self(), :start_session)

    Process.flag(:trap_exit, true)

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      gmcp: false,
      gmcp_supports: [],
      user_id: nil,
      config: %{}
    })
  end

  @impl GenServer
  def init(_), do: {:error, "should not be called"}

  @impl GenServer
  def handle_cast({:command, message, _}, state) do
    send_data(state, message)
    {:noreply, state}
  end

  def handle_cast({:gmcp, module, data}, state = %{gmcp: true}) do
    case module in state.gmcp_supports do
      true ->
        Logger.debug(["GMCP: Sending", module], type: :socket)
        module_char = module |> String.to_charlist()
        data_char = data |> String.to_charlist()
        message = [@iac, @sb, @gmcp] ++ module_char ++ [' '] ++ data_char ++ [@iac, @se]
        send_data(state, message)
        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end

  def handle_cast({:gmcp, _module, _data}, state) do
    {:noreply, state}
  end

  def handle_cast({:user_id, user_id}, state) do
    {:noreply, Map.put(state, :user_id, user_id)}
  end

  def handle_cast({:config, config}, state) do
    {:noreply, Map.put(state, :config, config)}
  end

  def handle_cast({:echo, message}, state) do
    send_data(state, "\n#{message |> Color.format(state.config)}\n")
    send_data(state, [@iac, @ga])
    {:noreply, state}
  end

  def handle_cast({:echo, message, :prompt}, state) do
    send_data(state, "\n#{message |> Color.format(state.config)}")
    send_data(state, [@iac, @ga])
    {:noreply, state}
  end

  def handle_cast(:start_session, state) do
    {:ok, pid} = Game.Session.start(self())
    Process.link(pid)

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
      :mccp ->
        Logger.info("Starting MCCP", type: :socket)
        zlib_context = :zlib.open()
        :zlib.deflateInit(zlib_context, 9)
        send_data(state, [@iac, @sb, @mccp, @iac, @se])

        {:noreply, Map.put(state, :zlib_context, zlib_context)}

      :mssp ->
        Logger.info("Sending MSSP", type: :socket)

        mssp = [@iac, @sb] ++ MSSP.name() ++ MSSP.players() ++ MSSP.uptime() ++ [@iac, @se]
        send_data(state, mssp)

        {:noreply, state}

      :iac ->
        {:noreply, state}

      :gmcp ->
        Logger.info("Will do GCMP", type: :socket)

        push_client_gui(state)

        {:noreply, Map.put(state, :gmcp, true)}

      {:gmcp, :will} ->
        Logger.info("Client is requesting GMCP", type: :socket)
        send_data(state, [@iac, @telnet_do, @gmcp])

        {:noreply, Map.put(state, :gmcp, true)}

      {:gmcp, data} ->
        data = data |> to_string() |> String.trim()
        Logger.debug(["GMCP: ", data], type: :socket)
        handle_gmcp(data, state)

      _ ->
        case state do
          %{session: pid} ->
            pid |> Game.Session.recv(data |> String.trim())

          _ ->
            send_data(state, data)
        end

        {:noreply, state}
    end)
  end

  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    Logger.info("Connection Closed", type: :socket)
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, :etimedout}, state) do
    %{socket: socket, transport: transport} = state
    Logger.info("Connection Timeout", type: :socket)
    disconnect(transport, socket, state)
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case state.session do
      ^pid ->
        {:ok, pid} = Game.Session.start_with_user(self(), state.user_id)
        Process.link(pid)

        {:noreply, %{state | session: pid}}

      _ ->
        {:stop, :error, state}
    end
  end

  # Disconnect the socket and optionally the session
  defp disconnect(transport, socket, state) do
    terminate_zlib_context(state)

    case state do
      %{session: pid} ->
        Logger.info("Disconnecting player", type: :socket)
        pid |> Game.Session.disconnect()

      _ ->
        nil
    end

    transport.close(socket)
  end

  @doc """
  Handle telnet options

  Multiple IAC dos might come in at the same time, so forward
  them along to us after handling one.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_options(data, socket, fun) do
    case data do
      <<@iac, @telnet_do, @mccp, data::binary>> ->
        forward_options(socket, data)
        fun.(:mccp)

      <<@iac, @telnet_do, @mssp, data::binary>> ->
        forward_options(socket, data)
        fun.(:mssp)

      <<@iac, @telnet_do, @gmcp, data::binary>> ->
        forward_options(socket, data)
        fun.(:gmcp)

      <<@iac, @will, @gmcp, data::binary>> ->
        forward_options(socket, data)
        fun.({:gmcp, :will})

      <<@iac, @sb, @gmcp, data::binary>> ->
        {data, forward} = split_iac_sb(data)
        forward_options(socket, forward)
        fun.({:gmcp, data})

      <<@iac, @telnet_dont, @mssp, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @telnet_do, @telnet_option_echo, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @telnet_dont, @telnet_option_echo, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, data::binary>> ->
        Logger.warn("Got weird iac data - #{inspect(data)}")
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
    Logger.debug(fn ->
      "Got a Core.Supports.Set of #{supports}"
    end, type: :socket)

    case Poison.decode(supports) do
      {:ok, supports} ->
        supports = remove_version_numbers(supports)
        supports = supports ++ state.gmcp_supports
        {:noreply, Map.put(state, :gmcp_supports, supports)}

      _ ->
        Logger.debug("There was an error decoding Core.Supports.Set", type: :socket)
        {:noreply, state}
    end
  end

  def handle_gmcp(_, state), do: {:noreply, state}

  defp split_iac_sb(<<@iac, @se, data::binary>>), do: {[], data}

  defp split_iac_sb(<<int::size(8), data::binary>>) do
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
    Logger.info("Terminating zlib stream", type: :socket)
    :zlib.deflate(zlib_context, "", :finish)
    :zlib.deflateEnd(zlib_context)
  end

  defp terminate_zlib_context(_), do: nil

  defp send_data(state = %{zlib_context: zlib_context}, data) do
    %{socket: socket, transport: transport} = state
    broadcast(state, data)
    data = :zlib.deflate(zlib_context, data, :full)
    transport.send(socket, data)
  end

  defp send_data(state = %{socket: socket, transport: transport}, data) do
    broadcast(state, data)
    transport.send(socket, data)
  end

  def broadcast(%{user_id: user_id}, data) when is_integer(user_id) do
    Web.Endpoint.broadcast("user:#{user_id}", "echo", %{data: data})
  end

  def broadcast(_, _), do: :ok

  defp remove_version_numbers(supports) do
    supports
    |> Enum.map(fn support ->
      support |> String.split(" ") |> List.first()
    end)
  end

  defp push_client_gui(state) do
    module_char = "Client.GUI" |> String.to_charlist()
    data_char = [@mudlet_version, RoutesHelper.public_page_url(Endpoint, :mudlet_package)] |> Enum.join("\n") |> String.to_charlist()
    message = [@iac, @sb, @gmcp] ++ module_char ++ [' '] ++ data_char ++ [@iac, @se]
    send_data(state, message)
  end
end
