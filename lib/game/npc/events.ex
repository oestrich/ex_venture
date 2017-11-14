defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Room

  alias Game.Message

  @doc """
  Act on events the NPC has been notified of
  """
  def act_on(state, action)
  def act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/entered", {:user, _, _}}) do
    npc.events
    |> Enum.filter(&(&1.type == "room/entered"))
    |> Enum.each(&(act_on_room_entered(npc_spawner, npc, &1)))

    :ok
  end
  def act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/heard", message}) do
    npc.events
    |> Enum.filter(&(&1.type == "room/heard"))
    |> Enum.each(&(act_on_room_heard(npc_spawner, npc, &1, message)))

    :ok
  end
  def act_on(_, _), do: :ok

  defp act_on_room_entered(npc_spawner, npc, event) do
    case event do
      %{action: %{type: "say", message: message}} ->
        npc_spawner.room_id |> @room.say(npc, Message.npc(npc, message))
      _ -> :ok
    end
  end

  defp act_on_room_heard(npc_spawner, npc, event, message) do
    case event do
      %{condition: %{regex: condition}, action: %{type: "say", message: event_message}} when condition != nil ->
        case Regex.match?(~r/#{condition}/i, message.message) do
          true ->
            npc_spawner.room_id |> @room.say(npc, Message.npc(npc, event_message))
          false ->
            :ok
        end
      %{action: %{type: "say", message: event_message}} ->
        npc_spawner.room_id |> @room.say(npc, Message.npc(npc, event_message))
      _ -> :ok
    end
  end
end
