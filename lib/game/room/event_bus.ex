defmodule Game.Room.EventBus do
  @moduledoc """
  A side process for rooms that notify characters

  Notifying in the main room process was too consuming, so do it in a side process
  """

  use GenServer

  alias Game.NPC
  alias Game.Room
  alias Game.Session

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: pid(room_id), id: "#{room_id}-notify")
  end

  def pid(id) do
    {:global, {Game.Room.EventBus, id}}
  end

  def notify(room_id, actor, event, players, npcs) do
    GenServer.cast(pid(room_id), {:notify, actor, event, players, npcs})
  end

  def init(room_id) do
    {:ok, %{room_id: room_id}, {:continue, :link}}
  end

  def handle_continue(:link, state) do
    case :global.whereis_name({Room, state.room_id}) do
      :undefined ->
        {:stop, :normal, state}

      pid ->
        Process.link(pid)
        {:noreply, state}
    end
  end

  def handle_cast({:notify, {:user, sender}, event, players, npcs}, state) do
    # don't send to the sender
    players
    |> Enum.reject(&(&1.id == sender.id))
    |> inform_players(event)

    npcs |> inform_npcs(event)

    {:noreply, state}
  end

  def handle_cast({:notify, {:npc, sender}, event, players, npcs}, state) do
    players |> inform_players(event)

    # don't send to the sender
    npcs
    |> Enum.reject(&(&1.id == sender.id))
    |> inform_npcs(event)

    {:noreply, state}
  end

  defp inform_players(players, action) do
    Enum.each(players, fn user ->
      Session.notify(user, action)
    end)
  end

  @spec inform_npcs(npcs :: list, action :: tuple) :: :ok
  defp inform_npcs(npcs, action) do
    Enum.each(npcs, fn npc ->
      NPC.notify(npc.id, action)
    end)
  end
end
