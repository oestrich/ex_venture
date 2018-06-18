defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  use Game.Environment

  import Game.Command.Skills, only: [find_target: 2]

  alias Data.Event
  alias Data.Exit
  alias Game.Channel
  alias Game.Character
  alias Game.Door
  alias Game.Format
  alias Game.Effect
  alias Game.Message
  alias Game.NPC
  alias Game.NPC.Combat
  alias Game.NPC.Status
  alias Game.Quest
  alias Metrics.CharacterInstrumenter
  alias Metrics.NPCInstrumenter

  @npc_reaction_time_ms Application.get_env(:ex_venture, :npc)[:reaction_time_ms]

  @doc """
  Instantiate events and start their ticking
  """
  @spec start_tick_events(State.t(), NPC.t()) :: State.t()
  def start_tick_events(state, npc) do
    tick_events =
      npc.events
      |> Enum.filter(fn event ->
        event.type == "tick"
      end)

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
  Perform an action, that was probably time delayed
  """
  @spec act(NPC.State.t(), map()) :: :ok | {:update, NPC.State.t()}
  def act(state, action) do
    case action.type do
      "emote" ->
        state =
          state
          |> emote_to_room(action.message)
          |> maybe_merge_status(action)
          |> update_character()

        {:update, state}

      "say" ->
        {:update, say_to_room(state, action.message)}

      _ ->
        :ok
    end
  end

  @doc """
  Perform an action, and then queue the next one
  """
  def act(state, action, actions) do
    return = act(state, action)

    case actions do
      [] ->
        return

      [action | actions] ->
        act_delayed(action, actions)

        return
    end
  end

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

  def act_on(state = %{npc: npc}, {"item/receive", character, instance}) do
    broadcast(npc, "item/receive", %{
      from: who(character),
      item: instance.id
    })

    state |> act_on_item_receive(character, instance)
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
      ^target ->
        {:update, %{state | target: nil}}

      _ ->
        :ok
    end
  end

  def act_on(state = %{npc: npc}, {"room/heard", message}) do
    broadcast(npc, "room/heard", %{
      type: message.type,
      name: message.sender.name,
      message: message.message,
      formatted: message.formatted
    })

    state =
      npc.events
      |> Enum.filter(&(&1.type == "room/heard"))
      |> Enum.reduce(state, &act_on_room_heard(&2, &1, message))

    {:update, state}
  end

  def act_on(state = %{npc: npc}, {"quest/completed", user, quest}) do
    broadcast(npc, "quest/completed", %{
      user: %{id: user.id, name: user.name},
      quest: %{id: quest.id}
    })

    message = Message.npc_tell(npc, quest.completed_message)
    Channel.tell({:user, user}, npc(state), message)

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
    {:ok, room} = @environment.look(room_id)

    case find_target(room, target) do
      {:ok, target} ->
        npc.events
        |> Enum.filter(&(&1.type == "combat/tick"))
        |> Combat.weighted_event()
        |> perform_combat_action(target, npc, state)

      {:error, :not_found} ->
        {:update, %{state | target: nil, combat: false}}
    end
  end

  defp perform_combat_action(nil, _target, _npc, state) do
    {:update, %{state | target: nil, combat: false}}
  end

  defp perform_combat_action(event, target, npc, state) do
    action = event.action

    effects =
      npc.stats
      |> Effect.calculate_stats_from_continuous_effects(state)
      |> Effect.calculate(action.effects)

    Character.apply_effects(
      target,
      effects,
      npc(state),
      Format.skill_usee(action.text, user: npc(state), target: target)
    )

    broadcast(npc, "combat/action", %{
      target: who(target),
      text: Format.skill_usee(action.text, user: npc(state), target: target),
      effects: effects
    })

    delay = round(Float.ceil(action.delay * 1000))
    notify_delayed({"combat/tick"}, delay)

    {:update, state}
  end

  @doc """
  Act on the `item/receive` event
  """
  def act_on_item_receive(state, character, item_instance)

  def act_on_item_receive(state, {:user, user}, item_instance) do
    npc = %{state.npc | id: state.npc.original_id}
    Quest.track_progress(user, {:item, item_instance, npc})
    :ok
  end

  def act_on_item_receive(state, _, _), do: state

  @doc """
  Act on the `room/entered` event.
  """
  @spec act_on_room_entered(NPC.State.t(), Character.t(), Event.t()) :: NPC.State.t()
  def act_on_room_entered(state, character, event)

  def act_on_room_entered(state, {:user, _}, event = %{action: %{type: "emote"}}) do
    state |> emote_to_room(event)
  end

  def act_on_room_entered(state, {:user, _}, event = %{action: %{type: "say"}}) do
    state |> say_to_room(event)
  end

  def act_on_room_entered(state, {:user, user}, %{action: %{type: "target"}}) do
    case state do
      %{combat: false} ->
        start_combat(state, user)

      %{target: nil} ->
        start_combat(state, user)

      _ ->
        state
    end
  end

  def act_on_room_entered(state, _character, _event), do: state

  defp start_combat(state = %{npc: npc}, user) do
    Character.being_targeted({:user, user}, npc(state))

    case state.combat do
      true ->
        :ok

      _ ->
        notify_delayed({"combat/tick"}, 1500)
    end

    broadcast(npc, "character/targeted", who({:user, user}))
    %{state | combat: true, target: Character.who({:user, user})}
  end

  def act_on_room_heard(state, event, message)
  def act_on_room_heard(state = %{npc: %{id: id}}, _, %{type: :npc, sender: %{id: id}}), do: state

  def act_on_room_heard(state, event, message) do
    case event do
      %{condition: %{regex: condition}} when condition != nil ->
        {:ok, regex} = Regex.compile(condition, "i")

        case Regex.match?(regex, message.message) do
          true ->
            _act_on_room_heard(state, event)

          false ->
            state
        end

      _ ->
        _act_on_room_heard(state, event)
    end
  end

  defp _act_on_room_heard(state, event = %{action: action}) do
    case action.type do
      "say" ->
        say_to_room(state, event)

      "emote" ->
        emote_to_room(state, event)

      _ ->
        state
    end
  end

  defp _act_on_room_heard(state, %{actions: []}) do
    state
  end

  defp _act_on_room_heard(state, %{actions: [action | actions]}) do
    case action.type do
      "say" ->
        say_to_room(state, action, actions)

      "emote" ->
        emote_to_room(state, action, actions)

      _ ->
        _act_on_room_heard(state, %{actions: actions})
    end
  end

  @doc """
  Act on a tick event
  """
  def act_on_tick(state = %{npc: %{stats: %{health_points: health_points}}}, _event)
      when health_points < 1,
      do: state

  def act_on_tick(state, event = %{action: %{type: "move"}}) do
    maybe_move_room(state, event)
  end

  def act_on_tick(state, event = %{action: %{type: "emote"}}) do
    emote_to_room(state, event)
  end

  def act_on_tick(state, event = %{action: %{type: "say"}}) do
    say_to_room(state, event)
  end

  def act_on_tick(state, event = %{action: %{type: "say/random"}}) do
    say_random_to_room(state, event)
  end

  def act_on_tick(state, _event), do: state

  def maybe_move_room(state = %{target: target}, _event) when target != nil, do: state

  def maybe_move_room(state = %{room_id: room_id, npc_spawner: npc_spawner}, event) do
    {:ok, starting_room} = @environment.look(npc_spawner.room_id)
    {:ok, room} = @environment.look(room_id)

    room_exit = Enum.random(room.exits)
    {:ok, new_room} = @environment.look(room_exit.finish_id)

    case can_move?(event.action, starting_room, room_exit, new_room) do
      true ->
        move_room(state, room, new_room, room_exit.direction)

      false ->
        state
    end
  end

  def can_move?(action, old_room, room_exit, new_room) do
    no_door_or_open?(room_exit) && under_maximum_move?(action, old_room, new_room) &&
      new_room.zone_id == old_room.zone_id
  end

  def no_door_or_open?(room_exit) do
    !(room_exit.has_door && Door.closed?(room_exit.door_id))
  end

  def move_room(state, old_room, new_room, direction) do
    CharacterInstrumenter.movement(:npc, fn ->
      @environment.unlink(old_room.id)
      @environment.leave(old_room.id, npc(state), {:leave, direction})
      @environment.enter(new_room.id, npc(state), {:enter, Exit.opposite(direction)})
      @environment.link(old_room.id)

      Enum.each(new_room.players, fn player ->
        NPC.delay_notify({"room/entered", {{:user, player}, :enter}}, milliseconds: @npc_reaction_time_ms)
      end)
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
  def emote_to_room(state, %{action: action}) do
    emote_to_room(state, action)
  end

  def emote_to_room(state, action) when is_map(action) do
    act_delayed(action)
    state
  end

  def emote_to_room(state = %{room_id: room_id}, message) when is_binary(message) do
    message = Message.npc_emote(state.npc, message)
    room_id |> @environment.emote(npc(state), message)
    broadcast(state.npc, "room/heard", message)

    state
  end

  def emote_to_room(state, action, actions) do
    act_delayed(action, actions)
    state
  end

  def maybe_merge_status(state, action) do
    case Map.has_key?(action, :status) do
      true ->
        state |> merge_status(action.status)

      false ->
        state
    end
  end

  @doc """
  Update the NPC's status after an emote
  """
  @spec merge_status(State.t(), map()) :: State.t()
  def merge_status(state, status) do
    status =
      case status do
        %{reset: true} ->
          %{npc: npc} = state

          %Status{
            key: "start",
            line: npc.status_line,
            listen: npc.status_listen
          }

        _ ->
          %Status{
            key: status.key,
            line: Map.get(status, :line, nil),
            listen: Map.get(status, :listen, nil)
          }
      end

    %{state | status: status}
  end

  @doc """
  Say the NPC's message to the room
  """
  def say_to_room(state, %{action: action}) do
    say_to_room(state, action)
  end

  def say_to_room(state, action) when is_map(action) do
    act_delayed(action)
    state
  end

  def say_to_room(state = %{room_id: room_id}, message) when is_binary(message) do
    message = Message.npc_say(state.npc, message)

    room_id |> @environment.say(npc(state), message)
    broadcast(state.npc, "room/heard", message)

    state
  end

  def say_to_room(state, action, actions) do
    act_delayed(action, actions)
    state
  end

  @doc """
  Say a random message to the room
  """
  def say_random_to_room(state = %{room_id: room_id}, %{action: %{messages: messages}}) do
    message = Enum.random(messages)
    message = Message.npc_say(state.npc, message)

    room_id |> @environment.say(npc(state), message)
    broadcast(state.npc, "room/heard", message)

    state
  end

  @doc """
  Broadcast a message to the NPC channel
  """
  def broadcast(npc, action, message \\ %{})

  def broadcast(npc, action, message = %Message{}) do
    broadcast(npc, action, %{
      type: message.type,
      name: message.sender.name,
      message: message.message,
      formatted: message.formatted
    })
  end

  def broadcast(%{id: id}, action, message) do
    NPCInstrumenter.event_acted_on(action)
    Web.Endpoint.broadcast("npc:#{id}", action, message)
  end

  def who({:npc, npc}), do: %{type: :npc, name: npc.name}
  def who({:user, user}), do: %{type: :user, name: user.name}

  defp npc(%{npc: npc, status: status}) when status != nil do
    {:npc, %{npc | status_line: status.line, status_listen: status.listen}}
  end

  defp npc(%{npc: npc}), do: {:npc, npc}

  defp update_character(state) do
    state.room_id |> @environment.update_character(npc(state))
    state
  end

  defp notify_delayed(action, delayed) do
    :erlang.send_after(delayed, self(), {:"$gen_cast", {:notify, action}})
  end

  defp act_delayed(action) do
    delay =
      case Map.get(action, :delay, 0) do
        0 ->
          0

        delay ->
          round(Float.ceil(delay * 1000))
      end

    :erlang.send_after(delay, self(), {:"$gen_cast", {:act, action}})
  end

  defp act_delayed(action, actions) do
    delay =
      case Map.get(action, :delay, 0) do
        0 ->
          0

        delay ->
          round(Float.ceil(delay * 1000))
      end

    :erlang.send_after(delay, self(), {:"$gen_cast", {:act, action, actions}})
  end
end
