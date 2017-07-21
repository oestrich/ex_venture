defmodule Game.NPC do
  @moduledoc """
  Server for an NPC
  """

  use GenServer
  use Game.Room

  alias Data.Repo
  alias Data.NPC

  alias Game.Message

  @doc """
  Starts a new NPC server

  Will have a registered name with the return from `Game.NPC.pid/1`.
  """
  def start_link(npc) do
    GenServer.start_link(__MODULE__, npc, name: pid(npc.id))
  end

  @doc """
  Helper for determining an NPCs registered process name
  """
  @spec pid(id :: Integer.id) :: String.t
  def pid(id), do: :"Game.NPC.npc_#{id}"

  @doc """
  Load all NPCs in the database
  """
  @spec all() :: [Map.t]
  def all() do
    NPC |> Repo.all
  end

  @doc """
  The NPC overheard a message

  Hook to respond to echos
  """
  @spec heard(id :: Integer.t, message :: Message.t) :: :ok
  def heard(id, message) do
    GenServer.cast(pid(id), {:heard, message})
  end

  def init(npc) do
    GenServer.cast(self(), :enter)
    {:ok, %{npc: npc}}
  end

  def handle_cast(:enter, state = %{npc: npc}) do
    @room.enter(npc.room_id, {:npc, npc})
    {:noreply, state}
  end
  def handle_cast({:heard, message}, state = %{npc: npc}) do
    case message.message do
      "Hello" <> _ ->
        npc.room_id |> @room.say(npc, Message.npc(npc, "How are you?"))
      _ -> nil
    end
    {:noreply, state}
  end
end
