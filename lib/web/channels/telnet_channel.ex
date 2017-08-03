defmodule Web.TelnetChannel do
  use Phoenix.Channel

  defmodule Monitor do
    use GenServer

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
      {:ok, %{channels: %{}}}
    end

    def handle_call({:monitor, channel_pid, session_pid}, _from, state) do
      Process.link(channel_pid)
      {:reply, :ok, put_channel(state, channel_pid, session_pid)}
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
      case Map.get(state.channels, pid, nil) do
        nil ->
          {:noreply, state}
        session_pid ->
          Game.Session.disconnect(session_pid)
          {:noreply, drop_channel(state, pid)}
      end
    end

    defp drop_channel(state, pid) do
      %{state | channels: Map.delete(state.channels, pid)}
    end

    defp put_channel(state, channel_pid, session_pid) do
      %{state | channels: Map.put(state.channels, channel_pid, session_pid)}
    end
  end

  defmodule Server do
    use GenServer

    alias Game.Color
    alias Web.TelnetChannel.Monitor

    def start_link(socket) do
      GenServer.start_link(__MODULE__, socket)
    end

    def init(socket) do
      GenServer.cast(self(), :start_session)
      {:ok, %{socket: socket}}
    end

    def handle_cast({:command, _message}, state) do
      {:noreply, state}
    end
    def handle_cast({:echo, message}, state) do
      send(state.socket.channel_pid, {:echo, message |> Color.strip_color})
      {:noreply, state}
    end
    def handle_cast({:echo, message, :prompt}, state) do
      send(state.socket.channel_pid, {:echo, message |> Color.strip_color, :prompt})
      {:noreply, state}
    end
    def handle_cast(:start_session, state) do
      {:ok, pid} = Game.Session.start(self())
      Monitor.monitor(self(), pid)
      {:noreply, Map.merge(state, %{session: pid})}
    end
    def handle_cast(:disconnect, state) do
      Monitor.demonitor(self())

      case state do
        %{session: pid} ->
          pid |> Game.Session.disconnect()
          send(state.socket.channel_pid, :disconnect)
        _ -> nil
      end
      {:stop, :normal, state}
    end
    def handle_cast({:recv, message}, state) do
      case state do
        %{session: pid} -> pid |> Game.Session.recv(message |> String.trim)
        _ -> nil
      end
      {:noreply, state}
    end
  end

  alias Web.TelnetChannel.Server

  def join("telnet:" <> _, _message, socket) do
    {:ok, pid} = Server.start_link(socket)
    {:ok, socket |> assign(:server_pid, pid)}
  end

  def handle_in("recv", %{"message" => message}, socket) do
    case socket.assigns do
      %{server_pid: pid} ->
        GenServer.cast(pid, {:recv, message})
      _ -> nil
    end
    {:noreply, socket}
  end

  def handle_info({:echo, message}, socket) do
    push socket, "echo", %{message: "\n#{message}\n"}
    {:noreply, socket}
  end
  def handle_info({:echo, message, :prompt}, socket) do
    push socket, "prompt", %{message: "\n#{message}"}
    {:noreply, socket}
  end
  def handle_info(:disconnect, socket) do
    push socket, "disconnect", %{}
    {:noreply, socket}
  end
end
