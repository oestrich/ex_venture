defmodule Web.TelnetChannel do
  @moduledoc """
  Telnet Channel

  Websockets channel that starts a GenServer that talks to the game session.
  """

  use Phoenix.Channel

  alias Metrics.PlayerInstrumenter
  alias Networking.Protocol
  alias Web.User

  defmodule Monitor do
    @moduledoc """
    TelnetChannel monitor

    When a telnet channel starts up it will start a genserver to connect
    to the session. The genserver will monitor itself via this module. When
    the telnet channel dies because of a disconnect, this module will receive
    an EXIT and disconnect the session.
    """

    use GenServer
    require Logger

    alias Web.TelnetChannel.Server

    def monitor(channel_pid, session_pid) do
      GenServer.call(__MODULE__, {:monitor, channel_pid, session_pid})
    end

    def demonitor(channel_pid) do
      GenServer.call(__MODULE__, {:demonitor, channel_pid})
    end

    def start_link() do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_) do
      Process.flag(:trap_exit, true)
      {:ok, %{channels: %{}, sessions: %{}}}
    end

    def handle_call({:monitor, channel_pid, session_pid}, _from, state) do
      Process.link(channel_pid)
      Process.link(session_pid)

      state =
        state
        |> put_channel(channel_pid, session_pid)
        |> put_session(session_pid, channel_pid)

      {:reply, :ok, state}
    end

    def handle_call({:demonitor, pid}, _from, state) do
      case Map.get(state.channels, pid, nil) do
        nil ->
          {:reply, :ok, state}

        _session_pid ->
          Process.unlink(pid)
          {:reply, :ok, drop_channel(state, pid)}
      end
    end

    def handle_info({:EXIT, pid, _reason}, state) do
      Logger.info(fn -> "Trapped an EXIT from the monitor" end, type: :monitor)

      case Map.get(state.channels, pid, nil) do
        nil ->
          maybe_restart_session(state, pid)

        session_pid ->
          Logger.info(fn -> "Sending a disconnect for the session" end, type: :monitor)
          Game.Session.disconnect(session_pid)

          {:noreply, drop_channel(state, pid)}
      end
    end

    defp maybe_restart_session(state, pid) do
      case Map.get(state.sessions, pid, nil) do
        nil ->
          {:noreply, state}

        channel_pid ->
          Server.restart_session(channel_pid)

          {:noreply, drop_session(state, pid)}
      end
    end

    defp drop_channel(state, pid) do
      %{state | channels: Map.delete(state.channels, pid)}
    end

    defp put_channel(state, channel_pid, session_pid) do
      %{state | channels: Map.put(state.channels, channel_pid, session_pid)}
    end

    defp drop_session(state, pid) do
      %{state | sessions: Map.delete(state.sessions, pid)}
    end

    defp put_session(state, session_pid, channel_pid) do
      %{state | sessions: Map.put(state.sessions, session_pid, channel_pid)}
    end
  end

  defmodule Server do
    @moduledoc """
    A GenServer that proxies between TelnetChannel and Session
    """

    use GenServer
    require Logger

    alias Web.TelnetChannel.Monitor

    def start_link(socket) do
      GenServer.start_link(__MODULE__, socket)
    end

    def restart_session(pid) do
      GenServer.cast(pid, :restart_session)
    end

    def init(socket) do
      GenServer.cast(self(), :start_session)

      state = %{
        socket: socket,
        user_id: nil,
        config: %{},
        restart_count: 0
      }

      {:ok, state}
    end

    def handle_cast({:command, _, command}, state) do
      case command do
        {:echo, true} ->
          send(state.socket.channel_pid, {:option, :echo, true})

        {:echo, false} ->
          send(state.socket.channel_pid, {:option, :echo, false})

        {:nop} ->
          :ok
      end

      {:noreply, state}
    end

    def handle_cast({:gmcp, module, data}, state) do
      send(state.socket.channel_pid, {:gmcp, module, data})
      {:noreply, state}
    end

    def handle_cast({:echo, message}, state) do
      send(state.socket.channel_pid, {:echo, message})
      {:noreply, state}
    end

    def handle_cast({:echo, message, :prompt}, state) do
      send(state.socket.channel_pid, {:echo, message, :prompt})
      {:noreply, state}
    end

    def handle_cast(:start_session, state) do
      PlayerInstrumenter.session_started(:websocket)
      {:ok, pid} = Game.Session.start(self())
      Monitor.monitor(self(), pid)
      GenServer.cast(self(), :attempt_sign_in)
      {:noreply, Map.merge(state, %{session: pid})}
    end

    def handle_cast(:attempt_sign_in, state) do
      case state.socket.assigns do
        %{user: user} ->
          Game.Session.sign_in(state.session, user)

        _ ->
          nil
      end

      {:noreply, state}
    end

    def handle_cast(:disconnect, state) do
      Monitor.demonitor(self())

      case state do
        %{session: pid} ->
          pid |> Game.Session.disconnect()
          send(state.socket.channel_pid, :disconnect)

        _ ->
          nil
      end

      {:stop, :normal, state}
    end

    def handle_cast({:recv, message}, state) do
      case state do
        %{session: pid} ->
          pid |> Game.Session.recv(message |> String.trim())
          {:noreply, state}

        _ ->
          {:noreply, state}
      end
    end

    def handle_cast({:recv_gmcp, module, data}, state) do
      with %{session: pid} <- state do
        pid |> Game.Session.recv_gmcp(module, data)
        {:noreply, state}
      else
        _ ->
          {:noreply, state}
      end
    end

    def handle_cast({:user_id, user_id}, state) do
      send(state.socket.channel_pid, {:user_id, user_id})
      {:noreply, %{state | user_id: user_id}}
    end

    def handle_cast({:config, config}, state) do
      send(state.socket.channel_pid, {:config, config})
      {:noreply, %{state | config: config}}
    end

    def handle_cast(:restart_session, state) do
      case state.restart_count do
        count when count > 5 ->
          Logger.info(
            fn ->
              "Session cannot recover. Giving up"
            end,
            type: :session
          )

          send(state.socket.channel_pid, {:echo, Protocol.error_disconnect_message()})

          ErrorReport.send_error("Session cannot be recovered. Game is offline.")

          {:stop, :normal, state}

        count ->
          delay = round(:math.pow(2, count) * 100)
          :erlang.send_after(delay, self(), :restart_session)
          :erlang.send_after(delay + 1_00, self(), {:mark_session_alive, count})
          {:noreply, state}
      end
    end

    def handle_info(:restart_session, state) do
      Logger.info(
        fn ->
          "Restarting a session"
        end,
        type: :session
      )

      {:ok, pid} = Game.Session.start_with_player(self(), state.user_id)

      Monitor.demonitor(self())
      Monitor.monitor(self(), pid)

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
  end

  alias Web.TelnetChannel.Server

  def join("telnet:" <> _, _message, socket) do
    socket =
      case socket.assigns do
        %{user_id: user_id} ->
          user = User.get(user_id)
          socket |> assign(:user, user)

        _ ->
          socket
      end

    {:ok, pid} = Server.start_link(socket)
    {:ok, socket |> assign(:server_pid, pid)}
  end

  def handle_in("recv", %{"message" => message}, socket) do
    case socket.assigns do
      %{server_pid: pid} ->
        GenServer.cast(pid, {:recv, message})

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_in("gmcp", %{"module" => module, "data" => data}, socket) do
    case socket.assigns do
      %{server_pid: pid} ->
        GenServer.cast(pid, {:recv_gmcp, module, data})

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_info({:user_id, user_id}, state) do
    {:noreply, Map.put(state, :user_id, user_id)}
  end

  def handle_info({:config, config}, state) do
    {:noreply, Map.put(state, :config, config)}
  end

  def handle_info({:option, :echo, flag}, socket) do
    push(socket, "option", %{type: "echo", echo: flag, sent_at: Timex.now()})
    {:noreply, socket}
  end

  def handle_info({:gmcp, module, data}, socket) do
    push(socket, "gmcp", %{module: module, data: data, sent_at: Timex.now()})
    {:noreply, socket}
  end

  def handle_info({:echo, message}, socket) do
    broadcast(socket, message)
    push(socket, "echo", %{message: "\n#{message}\n", sent_at: Timex.now()})
    {:noreply, socket}
  end

  def handle_info({:echo, message, :prompt}, socket) do
    broadcast(socket, message)
    push(socket, "prompt", %{message: "\n#{message}", sent_at: Timex.now()})
    {:noreply, socket}
  end

  def handle_info(:disconnect, socket) do
    push(socket, "disconnect", %{sent_at: Timex.now()})
    {:noreply, socket}
  end

  def broadcast(%{user_id: user_id}, data) when is_integer(user_id) do
    Web.Endpoint.broadcast("user:#{user_id}", "echo", %{data: data})
  end

  def broadcast(_, _), do: :ok
end
