defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Room

  import Game.Command.Skills, only: [find_target: 2]

  alias Data.Event
  alias Data.Exit
  alias Data.Room
  alias Game.Character
  alias Game.Door
  alias Game.Effect
  alias Game.Message
  alias Game.NPC
  alias Game.NPC.Combat

  @rand Application.get_env(:ex_venture, :game)[:rand]

  @doc """
  Act on events the NPC has been notified of
  """
  @spec act_on(state :: NPC.State.t, action :: {String.t, any()}) :: :ok | {:update, NPC.State.t}
  def act_on(state, action)
  def act_on(state = %{npc: npc}, {"combat/tick"}) do
    broadcast(npc, "combat/tick")
    state |> act_on_combat_tick()
  end
  def act_on(state = %{npc: npc}, {"room/entered", character}) do
    broadcast(npc, "room/entered", who(character))

    state =
      npc.events
      |> Enum.filter(&(&1.type == "room/entered"))
      |> Enum.reduce(state, (&(act_on_room_entered(&2, character, &1))))

    {:update, state}
  end
  def act_on(state = %{npc: npc}, {"room/leave", character}) do
    broadcast(npc, "room/leave", who(character))

    target = Map.get(state, :target, nil)
    case Character.who(character) do
      ^target -> {:update, %{state | target: nil}}
      _ -> :ok
    end
  end
  def act_on(%{room_id: room_id, npc: npc}, {"room/heard", message}) do
    broadcast(npc, "room/heard", %{
      type: message.type,
      name: message.sender.name,
      message: message.message,
      formatted: message.formatted,
    })

    npc.events
    |> Enum.filter(&(&1.type == "room/heard"))
    |> Enum.each(&(act_on_room_heard(room_id, npc, &1, message)))

    :ok
  end
  def act_on(state = %{npc: npc}, {"tick"}) do
    broadcast(npc, "combat/tick")
    state =
      npc.events
      |> Enum.filter(&(&1.type == "tick"))
      |> Enum.reduce(state, (&(act_on_tick(&2, &1))))

    {:update, state}
  end
  def act_on(_, _), do: :ok

  @doc """
  Act on a combat tick, if the NPC has a target, pick an event and apply those effects
  """
  def act_on_combat_tick(%{target: nil}), do: :ok
  def act_on_combat_tick(state = %{room_id: room_id, npc: npc, target: target}) do
    room = @room.look(room_id)

    case find_target(room, target) do
      nil -> {:update, %{state | target: nil}}
      target ->
        event =
          npc.events
          |> Enum.filter(&(&1.type == "combat/tick"))
          |> Combat.weighted_event()

        action = event.action
        effects = npc.stats |> Effect.calculate(action.effects)
        Character.apply_effects(target, effects, {:npc, npc}, action.text)

        delay = round(Float.ceil(action.delay * 1000))
        notify_delayed({"combat/tick"}, delay)

        {:update, state}
    end
  end

  @doc """
  Act on the `room/entered` event.
  """
  @spec act_on_room_entered(state :: NPC.State.t, character :: Character.t, event :: Event.t) :: NPC.State.t
  def act_on_room_entered(state, character, event)
  def act_on_room_entered(state, {:user, _, _}, %{action: %{type: "say", message: message}}) do
    %{room_id: room_id, npc: npc} = state
    room_id |> @room.say(npc, Message.npc(npc, message))
    state
  end
  def act_on_room_entered(state = %{npc: npc}, {:user, _, user}, %{action: %{type: "target"}}) do
    Character.being_targeted({:user, user}, {:npc, npc})
    notify_delayed({"combat/tick"}, 1500)
    %{state | target: Character.who({:user, user})}
  end
  def act_on_room_entered(state, _character, _event), do: state

  def act_on_room_heard(room_id, npc, event, message) do
    case event do
      %{condition: %{regex: condition}, action: %{type: "say", message: event_message}} when condition != nil ->
        case Regex.match?(~r/#{condition}/i, message.message) do
          true ->
            room_id |> @room.say(npc, Message.npc(npc, event_message))
          false ->
            :ok
        end
      %{action: %{type: "say", message: event_message}} ->
        room_id |> @room.say(npc, Message.npc(npc, event_message))
      _ -> :ok
    end
  end

  @doc """
  Act on a tick event
  """
  def act_on_tick(state, event = %{action: %{type: "move"}}) do
    case move_room?(event) do
      true -> maybe_move_room(state, event)
      false -> state
    end
  end
  def act_on_tick(state, _event), do: state

  def maybe_move_room(state = %{target: target}, _event) when target != nil, do: state
  def maybe_move_room(state = %{room_id: room_id, npc_spawner: npc_spawner}, event) do
    starting_room = @room.look(npc_spawner.room_id)
    room = @room.look(room_id)

    direction =
      room
      |> Room.exits()
      |> Enum.random()

    room_exit = room |> Exit.exit_to(direction)
    new_room = @room.look(Map.get(room_exit, String.to_atom("#{direction}_id")))

    case no_door_or_open?(room_exit) && under_maximum_move?(event.action, starting_room, new_room) do
      true -> move_room(state, room, new_room)
      false -> state
    end
  end

  def no_door_or_open?(room_exit) do
    !(room_exit.has_door && Door.closed?(room_exit.id))
  end

  def move_room(state = %{npc: npc}, old_room, new_room) do
    @room.leave(old_room.id, {:npc, npc})
    @room.enter(new_room.id, {:npc, npc})

    state
    |> Map.put(:room_id, new_room.id)
  end

  @doc """
  Determine if the new chosen room is too far to pick
  """
  def under_maximum_move?(action, old_room, new_room) do
    abs(old_room.x - new_room.x) <= action.max_distance &&
      abs(old_room.y - new_room.y) <= action.max_distance
  end

  @doc """
  Determine if the NPC should move rooms

  Uses `:rand` by default
  """
  @spec move_room?(event :: Event.t, rand :: atom) :: boolean
  def move_room?(event, rand \\ @rand)
  def move_room?(%{action: %{chance: chance}}, rand) do
    rand.uniform(100) <= chance
  end

  defp broadcast(npc, action) do
    broadcast(npc, action, %{})
  end
  defp broadcast(%{id: id}, action, message) do
    Web.Endpoint.broadcast!("npc:#{id}", action, message)
  end

  defp who({:npc, npc}), do: %{type: :npc, name: npc.name}
  defp who({:user, user}), do: %{type: :user, name: user.name}
  defp who({:user, _, user}), do: %{type: :user, name: user.name}

  defp notify_delayed(action, delayed) do
    :erlang.send_after(delayed, self(), {:"$gen_cast", {:notify, action}})
  end
end
