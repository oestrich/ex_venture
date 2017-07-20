defmodule Game.NPC do
  use GenServer
  use Game.Room

  alias Data.Repo
  alias Data.NPC

  def start_link(npc) do
    GenServer.start_link(__MODULE__, npc, name: pid(npc.id))
  end

  def pid(id), do: :"Game.NPC.npc_#{id}"

  @doc """
  Load all NPCs in the database
  """
  @spec all() :: [Map.t]
  def all() do
    NPC |> Repo.all
  end

  def init(npc) do
    GenServer.cast(self(), :enter)
    {:ok, %{npc: npc}}
  end

  def handle_cast(:enter, state = %{npc: npc}) do
    @room.enter(npc.room_id, {:npc, npc})
    {:noreply, state}
  end
end
