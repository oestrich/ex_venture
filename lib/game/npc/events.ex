defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Room

  import Game.Command.Skills, only: [find_target: 2]

  alias Data.Event
  alias Data.Exit
  alias Data.Room
  alias Game.Channel
  alias Game.Character
  alias Game.Door
  alias Game.Format
  alias Game.Effect
  alias Game.Message
  alias Game.NPC
  alias Game.NPC.Combat

  @doc """
  Filters to tick events and adds a UUID
  """
  def instantiate_ticks(events) do
    events
    |> Enum.filter(&(&1.type == "tick"))
    |> Enum.map(fn event ->
      Map.put(event, :id, UUID.uuid4())
    end)
  end

  @doc """
  Instantiate events and start their ticking
  """
  @spec start_tick_events(State.t(), NPC.t()) :: State.t()
  def start_tick_events(state, npc) do
    tick_events = npc.events |> instantiate_ticks()
    tick_events |> Enum.each(&delay_event/1)
    %{state | tick_events: tick_events}
  end

  @doc """
  Calculate a delay and `:erlang.send_after/3` the event

  `{:tick, id}` is the message.
  """
  @spec delay_event(map()) :: :ok
  def delay_event(tick_event) do
    :erlang.send_after(calculate_delay(tick_event) * 1000, self(), {:tick, tick_event.id})
  end

  @doc """
  Calculates how long the next event firing should be delayed for, in seconds

  Uses the `wait` and `chance` keys in the action
  """
  @spec calculate_delay(Event.t()) :: integer()
  def calculate_delay(event, rand \\ :rand) do
    wait = Map.get(event.action, :wait, 60)
    chance = Map.get(event.action, :wait, 60)

    wait + rand.uniform(chance)
  end

  #
  # Notifications & Acting on
  #

  @doc """
  Act on events the NPC has been notified of
  """
  @spec act_on(NPC.State.t(), {String.t(), any()}) :: :ok | {:update, NPC.State.t()}
  def act_on(state, action)

  def act_on(state = %{npc: npc}, {"character/died", character, :character, from}) do
    broadcast(npc, "character/died", who(character))
    state |> act_on_character_died(character, from)
  end

  def act_on(state = %{npc: npc}, {"combat/tick"}) do
    broadcast(npc, "combat/tick")
    state |> act_on_combat_tick()
  end

  def act_on(state = %{npc: npc}, {"room/entered", {character, _reason}}) do
    broadcast(npc, "room/entered", who(character))

    state =
      npc.events
      |> Enum.filter(&(&1.type == "room/entered"))
      |> Enum.reduce(state, &act_on_room_entered(&2, character, &1))

    {:update, state}
  end

  def act_on(state = %{npc: npc}, {"room/leave", {character, _reason}}) do
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
      formatted: message.formatted
    })

    npc.events
    |> Enum.filter(&(&1.type == "room/heard"))
    |> Enum.each(&act_on_room_heard(room_id, npc, &1, message))

    :ok
  end

  def act_on(%{npc: npc}, {"quest/completed", user, quest}) do
    broadcast(npc, "quest/completed", %{
      user: %{id: user.id, name: user.name},
      quest: %{id: quest.id}
    })

    message = Message.npc_tell(npc, quest.completed_message)
    Channel.tell({:user, user}, {:npc, npc}, message)

    :ok
  end

  def act_on(_, _), do: :ok

  @doc """
  Act on a character death notification

  Clear the target if the target matches
  """
  def act_on_character_died(%{target: nil}, _character, _from), do: :ok

  def act_on_character_died(state, character, _from) do
    case Character.who(character) == Character.who(state.target) do
      true ->
        {:update, Map.put(state, :target, nil)}
      false ->
        :ok
    end
  end

  @doc """
  Act on a combat tick, if the NPC has a target, pick an event and apply those effects
  """
  def act_on_combat_tick(state = %{target: nil}), do: {:update, %{state | combat: false}}

  def act_on_combat_tick(state = %{room_id: room_id, npc: npc, target: target}) do
    room = @room.look(room_id)

    case find_target(room, target) do
      nil ->
        {:update, %{state | target: nil, combat: false}}

      target ->
        event =
          npc.events
          |> Enum.filter(&(&1.type == "combat/tick"))
          |> Combat.weighted_event()

        action = event.action
        effects = npc.stats |> Effect.calculate(action.effects)

        Character.apply_effects(
          target,
          effects,
          {:npc, npc},
          Format.skill_usee(action.text, user: {:npc, npc})
        )

        delay = round(Float.ceil(action.delay * 1000))
        notify_delayed({"combat/tick"}, delay)

        {:update, state}
    end
  end

  @doc """
  Act on the `room/entered` event.
  """
  @spec act_on_room_entered(NPC.State.t(), Character.t(), Event.t()) :: NPC.State.t()
  def act_on_room_entered(state, character, event)

  def act_on_room_entered(state, {:user, _}, %{action: %{type: "say", message: message}}) do
    %{room_id: room_id, npc: npc} = state
    room_id |> @room.say({:npc, npc}, Message.npc(npc, message))
    state
  end

  def act_on_room_entered(state = %{npc: npc, combat: false}, {:user, user}, %{action: %{type: "target"}}) do
    Character.being_targeted({:user, user}, {:npc, npc})
    notify_delayed({"combat/tick"}, 1500)
    %{state | combat: true, target: Character.who({:user, user})}
  end

  def act_on_room_entered(state, _character, _event), do: state

  def act_on_room_heard(room_id, npc, event, message)
  def act_on_room_heard(_, %{id: id}, _, %{type: :npc, sender: %{id: id}}), do: :ok

  def act_on_room_heard(room_id, npc, event, message) do
    case event do
      %{condition: %{regex: condition}, action: %{type: "say", message: event_message}}
      when condition != nil ->
        case Regex.match?(~r/#{condition}/i, message.message) do
          true ->
            room_id |> @room.say({:npc, npc}, Message.npc(npc, event_message))

          false ->
            :ok
        end

      %{action: %{type: "say", message: event_message}} ->
        room_id |> @room.say({:npc, npc}, Message.npc(npc, event_message))

      _ ->
        :ok
    end
  end

  @doc """
  Act on a tick event
  """
  def act_on_tick(state = %{npc: %{stats: %{health: health}}}, _event) when health < 1, do: state

  def act_on_tick(state, event = %{action: %{type: "move"}}) do
    maybe_move_room(state, event)
  end

  def act_on_tick(state, event = %{action: %{type: "emote"}}) do
    emote_to_room(state, event)
  end

  def act_on_tick(state, event = %{action: %{type: "say"}}) do
    say_to_room(state, event)
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

    case can_move?(event.action, starting_room, room_exit, new_room) do
      true -> move_room(state, room, new_room)
      false -> state
    end
  end

  def can_move?(action, old_room, room_exit, new_room) do
    no_door_or_open?(room_exit) && under_maximum_move?(action, old_room, new_room) &&
      new_room.zone_id == old_room.zone_id
  end

  def no_door_or_open?(room_exit) do
    !(room_exit.has_door && Door.closed?(room_exit.id))
  end

  def move_room(state = %{npc: npc}, old_room, new_room) do
    @room.unlink(old_room.id)
    @room.leave(old_room.id, {:npc, npc})
    @room.enter(new_room.id, {:npc, npc})
    @room.link(old_room.id)

    Enum.each(new_room.players, fn player ->
      GenServer.cast(self(), {:notify, {"room/entered", {{:user, player}, :enter}}})
    end)

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
  Emote the NPC's message to the room
  """
  def emote_to_room(state = %{room_id: room_id, npc: npc}, %{action: %{message: message}}) do
    room_id |> @room.emote({:npc, npc}, Message.npc_emote(npc, message))
    state
  end

  @doc """
  Say the NPC's message to the room
  """
  def say_to_room(state = %{room_id: room_id, npc: npc}, %{action: %{message: message}}) do
    room_id |> @room.say({:npc, npc}, Message.npc_say(npc, message))
    state
  end

  defp broadcast(npc, action) do
    broadcast(npc, action, %{})
  end

  defp broadcast(%{id: id}, action, message) do
    Web.Endpoint.broadcast("npc:#{id}", action, message)
  end

  defp who({:npc, npc}), do: %{type: :npc, name: npc.name}
  defp who({:user, user}), do: %{type: :user, name: user.name}
  defp who({:user, _, user}), do: %{type: :user, name: user.name}

  defp notify_delayed(action, delayed) do
    :erlang.send_after(delayed, self(), {:"$gen_cast", {:notify, action}})
  end
end
