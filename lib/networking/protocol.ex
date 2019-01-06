defmodule Networking.Protocol do
  @moduledoc """
  Ranch protocol implementation, socket genserver
  """

  use GenServer
  require Logger

  alias Game.Color
  alias Metrics.PlayerInstrumenter
  alias Networking.GMCP
  alias Networking.MSSP
  alias Networking.MXP
  alias Web.Endpoint
  alias Web.Router.Helpers, as: RoutesHelper

  @type state :: map()

  @mudlet_version 16

  @behaviour :ranch_protocol
  @behaviour Networking.Socket

  @iac 255
  @will 251
  @wont 252
  @telnet_do 253
  @telnet_dont 254
  @sb 250
  @se 240
  @nop 241
  @telnet_option_echo 1
  @ga 249
  @ayt 246

  @mssp 70
  @mccp 86
  @mxp 91
  @gmcp 201

  @impl :ranch_protocol
  def start_link(ref, _socket, transport, opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  def error_disconnect_message() do
    "{red}ERROR{/red}: {white}The game appears to be offline. Please try connecting later.{/white}"
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
    GenServer.cast(socket, {:command, <<@iac, @wont, @telnet_option_echo>>, {:echo, true}})
  end

  def tcp_option(socket, :echo, false) do
    GenServer.cast(socket, {:command, <<@iac, @will, @telnet_option_echo>>, {:echo, false}})
  end

  @impl true
  def nop(socket) do
    GenServer.cast(socket, {:command, <<@iac, @nop>>, {:nop}})
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
  Set the character id of the socket
  """
  @spec set_character_id(pid, integer()) :: :ok
  @impl Networking.Socket
  def set_character_id(socket, character_id) do
    GenServer.cast(socket, {:character_id, character_id})
  end

  @impl Networking.Socket
  def set_config(socket, config) do
    GenServer.cast(socket, {:config, config})
  end

  def init(ref, transport, _opts) do
    Logger.info("Player connecting", type: :socket)
    PlayerInstrumenter.session_started(:telnet)

    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    GenServer.cast(self(), :start_session)

    Process.flag(:trap_exit, true)

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      gmcp: false,
      gmcp_supports: [],
      mxp: false,
      character_id: nil,
      restart_count: 0,
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
    case GMCP.message_allowed?(state, module) do
      true ->
        Logger.debug(["GMCP: Sending", module], type: :socket)
        send_data(state, <<@iac, @sb, @gmcp>> <> module <> " " <> data <> <<@iac, @se>>)

        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end

  def handle_cast({:gmcp, _module, _data}, state) do
    {:noreply, state}
  end

  def handle_cast({:character_id, character_id}, state) do
    {:noreply, Map.put(state, :character_id, character_id)}
  end

  def handle_cast({:config, config}, state) do
    {:noreply, Map.put(state, :config, config)}
  end

  def handle_cast({:echo, message}, state) do
    message =
      message
      |> MXP.handle_mxp(mxp: state.mxp)
      |> Color.format(state.config)
      |> String.trim()

    send_data(state, "\n#{message}\n")
    send_data(state, <<@iac, @ga>>)
    {:noreply, state}
  end

  def handle_cast({:echo, message, :prompt}, state) do
    message =
      message
      |> MXP.handle_mxp(mxp: state.mxp)
      |> Color.format(state.config)
      |> String.trim()

    send_data(state, "\n#{message}")
    send_data(state, <<@iac, @ga>>)
    {:noreply, state}
  end

  def handle_cast(:start_session, state) do
    {:ok, pid} = Game.Session.start(self())
    Process.link(pid)

    send_data(state, <<@iac, @will, @mccp>>)
    send_data(state, <<@iac, @will, @mssp>>)
    send_data(state, <<@iac, @will, @gmcp>>)
    send_data(state, <<@iac, @will, @mxp>>)

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
        send_data(state, <<@iac, @sb, @mccp, @iac, @se>>)

        {:noreply, Map.put(state, :zlib_context, zlib_context)}

      :mssp ->
        Logger.info("Sending MSSP", type: :socket)

        mssp = <<@iac, @sb, @mssp>> <> MSSP.name() <> MSSP.players() <> MSSP.uptime() <> <<@iac, @se>>
        send_data(state, mssp)

        {:noreply, state}

      :ayt ->
        {:noreply, state}

      :iac ->
        {:noreply, state}

      :mxp ->
        Logger.info("Will do MXP", type: :socket)
        send_data(state, <<@iac, @sb, @mxp, @iac, @se>>)
        {:noreply, Map.put(state, :mxp, true)}

      :gmcp ->
        Logger.info("Will do GCMP", type: :socket)

        state
        |> push_client_gui()
        |> push_client_map()

        {:noreply, Map.put(state, :gmcp, true)}

      {:gmcp, :will} ->
        Logger.info("Client is requesting GMCP", type: :socket)
        send_data(state, <<@iac, @telnet_do, @gmcp>>)

        {:noreply, Map.put(state, :gmcp, true)}

      {:gmcp, data} ->
        data = data |> to_string() |> String.trim()
        Logger.debug(["GMCP: ", data], type: :socket)
        handle_gmcp(data, state)

      _ ->
        case state do
          %{session: pid} ->
            pid |> Game.Session.recv(data |> String.trim() |> MXP.strip_mxp())

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
        restart_session(state)

      _ ->
        {:stop, :error, state}
    end
  end

  def handle_info(:restart_session, state) do
    {:ok, pid} = Game.Session.start_with_player(self(), state.character_id)
    Process.link(pid)

    state =
      state
      |> Map.put(:session, pid)
      |> Map.put(:restart_count, state.restart_count + 1)

    {:noreply, state}
  end

  def handle_info({:mark_session_alive, count}, state) do
    case state.restart_count == count do
      true ->
        {:noreply, Map.put(state, :restart_count, 0)}

      false ->
        {:noreply, state}
    end
  end

  defp restart_session(state) do
    case state.restart_count do
      count when count > 5 ->
        Logger.info(
          fn ->
            "Session cannot recover. Giving up"
          end,
          type: :session
        )

        ErrorReport.send_error("Session cannot be recovered. Game is offline.")
        echo(self(), error_disconnect_message())
        disconnect(self())

        {:noreply, state}

      count ->
        delay = round(:math.pow(2, count) * 100)
        :erlang.send_after(delay, self(), :restart_session)
        :erlang.send_after(delay + 1_00, self(), {:mark_session_alive, count})
        {:noreply, state}
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

      <<@iac, @telnet_dont, @mccp, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @telnet_do, @mssp, data::binary>> ->
        forward_options(socket, data)
        fun.(:mssp)

      <<@iac, @telnet_dont, @mssp, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @telnet_do, @gmcp, data::binary>> ->
        forward_options(socket, data)
        fun.(:gmcp)

      <<@iac, @telnet_dont, @gmcp, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @will, @gmcp, data::binary>> ->
        forward_options(socket, data)
        fun.({:gmcp, :will})

      <<@iac, @telnet_do, @mxp, data::binary>> ->
        forward_options(socket, data)
        fun.(:mxp)

      <<@iac, @telnet_dont, @mxp, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @sb, @gmcp, data::binary>> ->
        {data, forward} = split_iac_sb(data)
        forward_options(socket, forward)
        fun.({:gmcp, data})

      <<@iac, @telnet_do, @telnet_option_echo, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @telnet_dont, @telnet_option_echo, data::binary>> ->
        forward_options(socket, data)
        fun.(:iac)

      <<@iac, @ayt, data::binary>> ->
        forward_options(socket, data)
        fun.(:ayt)

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
    Logger.debug(
      fn ->
        "Got a Core.Supports.Set of #{supports}"
      end,
      type: :socket
    )

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

  def handle_gmcp("External.Discord.Hello" <> _extra, state) do
    state.session |> Game.Session.recv_gmcp("External.Discord.Hello")

    {:noreply, state}
  end

  def handle_gmcp("External.Discord.Get" <> _extra, state) do
    state.session |> Game.Session.recv_gmcp("External.Discord.Get")

    {:noreply, state}
  end

  def handle_gmcp(message, state) do
    [module | _] = String.split(message, " ")
    module = String.trim(module)
    data = String.replace(message, module, "", global: false)

    with {:ok, data} <- Poison.decode(data) do
      state.session |> Game.Session.recv_gmcp(module, data)

      {:noreply, state}
    else
      _ ->
        {:noreply, state}
    end
  end

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

  def broadcast(%{character_id: character_id}, data) when is_integer(character_id) do
    case data do
      <<@iac, _data::binary()>> ->
        :ok

      _ ->
        Web.Endpoint.broadcast("character:#{character_id}", "echo", %{data: data})
    end
  end

  def broadcast(_, _), do: :ok

  defp remove_version_numbers(supports) do
    supports
    |> Enum.map(fn support ->
      support |> String.split(" ") |> List.first()
    end)
  end

  defp push_client_gui(state) do
    data = "#{@mudlet_version}\n#{RoutesHelper.public_page_url(Endpoint, :mudlet_package)}"
    message = <<@iac, @sb, @gmcp>> <> "Client.GUI " <> data <> <<@iac, @se>>
    send_data(state, message)

    state
  end

  defp push_client_map(state) do
    data = %{url: RoutesHelper.public_page_url(Endpoint, :map), version: "1"}
    data = Poison.encode!(data)

    message = <<@iac, @sb, @gmcp>> <> "Client.Map " <> data <> <<@iac, @se>>
    send_data(state, message)

    state
  end
end
