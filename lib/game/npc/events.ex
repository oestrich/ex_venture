defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Room

  alias Game.Message

  def act_on(state, action)
  def act_on(%{npc_spawner: npc_spawner, npc: npc}, {:enter, {:user, _, _}}) do
    npc.events
    |> Enum.filter(&(&1.type == "room/entered"))
    |> Enum.each(&(act_on_room_entered(npc_spawner, npc, &1)))

    :ok
  end
  def act_on(_, _), do: :ok

  defp act_on_room_entered(npc_spawner, npc, event) do
    case event do
      %{action: "say", arguments: [message]} ->
        npc_spawner.room_id |> @room.say(npc, Message.npc(npc, message))
      _ -> :ok
    end
  end
end
