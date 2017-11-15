defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Room

  alias Data.Event
  alias Game.Character
  alias Game.Message
  alias Game.NPC

  @doc """
  Act on events the NPC has been notified of
  """
  @spec act_on(state :: NPC.State.t, action :: {String.t, any()}) :: :ok | {:update, NPC.State.t}
  def act_on(state, action)
  def act_on(state = %{npc: npc}, {"room/entered", character}) do
    state =
      npc.events
      |> Enum.filter(&(&1.type == "room/entered"))
      |> Enum.reduce(state, (&(act_on_room_entered(&2, character, &1))))

    {:update, state}
  end
  def act_on(state, {"room/leave", character}) do
    target = Map.get(state, :target, nil)
    case Character.who(character) do
      ^target -> {:update, %{state | target: nil}}
      _ -> :ok
    end
  end
  def act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/heard", message}) do
    npc.events
    |> Enum.filter(&(&1.type == "room/heard"))
    |> Enum.each(&(act_on_room_heard(npc_spawner, npc, &1, message)))

    :ok
  end
  def act_on(_, _), do: :ok

  @doc """
  Act on the `room/entered` event.
  """
  @spec act_on_room_entered(state :: NPC.State.t, character :: Character.t, event :: Event.t) :: NPC.State.t
  def act_on_room_entered(state, character, event)
  def act_on_room_entered(state, {:user, _, _}, %{action: %{type: "say", message: message}}) do
    %{npc_spawner: npc_spawner, npc: npc} = state
    npc_spawner.room_id |> @room.say(npc, Message.npc(npc, message))
    state
  end
  def act_on_room_entered(state = %{npc: npc}, {:user, _, user}, %{action: %{type: "target"}}) do
    Character.being_targeted({:user, user}, {:npc, npc})
    %{state | target: Character.who({:user, user})}
  end
  def act_on_room_entered(state, _character, _event), do: state

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
