defmodule Web.NPCChannel do
  @moduledoc """
  NPC Channel for admins
  """

  use Phoenix.Channel

  require Logger

  alias Game.NPC

  defmodule Monitor do
    @moduledoc """
    NPCChannel monitor

    Monitor the NPC channel for a disconnect. When the channel is killed because
    of a disconnect, then the NPC should have control released.
    """

    use GenServer

    def monitor(channel_pid, npc_id) do
      GenServer.call(__MODULE__, {:monitor, channel_pid, npc_id})
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

    def handle_call({:monitor, channel_pid, npc_id}, _from, state) do
      Process.link(channel_pid)
      {:reply, :ok, put_channel(state, channel_pid, npc_id)}
    end

    def handle_call({:demonitor, pid}, _from, state) do
      case Map.get(state.channels, pid, nil) do
        nil ->
          {:reply, :ok, state}

        _npc_id ->
          Process.unlink(pid)
          {:reply, :ok, drop_channel(state, pid)}
      end
    end

    def handle_info({:EXIT, pid, _reason}, state) do
      case Map.get(state.channels, pid, nil) do
        nil ->
          {:noreply, state}

        npc_id ->
          NPC.release(npc_id)
          {:noreply, drop_channel(state, pid)}
      end
    end

    defp drop_channel(state, pid) do
      %{state | channels: Map.delete(state.channels, pid)}
    end

    defp put_channel(state, channel_pid, npc_id) do
      %{state | channels: Map.put(state.channels, channel_pid, npc_id)}
    end
  end

  # attempt to control an npc
  # the npc will only allow one controller at a time
  # the npc will expire the control after a certain number of ticks
  # will keep control as it keeps getting messages
  def join("npc:" <> id, _message, socket) do
    %{user: user} = socket.assigns
    {id, _} = Integer.parse(id)

    socket = socket |> assign(:npc_id, id)

    Logger.info("Admin (#{user.id}) is attempting to control NPC (#{id})")

    case NPC.control(id) do
      :ok ->
        Monitor.monitor(self(), id)
        :telemetry.execute([:exventure, :admin, :npc, :control], %{count: 1})

        {:ok, socket}

      _ ->
        {:error, %{reason: "already controlled"}}
    end
  end

  def handle_in("say", %{"message" => message}, socket) do
    :telemetry.execute([:exventure, :admin, :npc, :control, :action], %{count: 1}, %{action: "say"})
    NPC.say(socket.assigns.npc_id, message)
    {:noreply, socket}
  end

  def handle_in("emote", %{"message" => message}, socket) do
    :telemetry.execute([:exventure, :admin, :npc, :control, :action], %{count: 1}, %{action: "emote"})
    NPC.emote(socket.assigns.npc_id, message)
    {:noreply, socket}
  end
end
