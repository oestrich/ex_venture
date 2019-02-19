defmodule Game.NPC.Events do
  @moduledoc """
  Handle events that NPCs have defined
  """

  alias Data.Events.StateTicked
  alias Game.Channel
  alias Game.Character
  alias Game.Events.RoomEntered
  alias Game.Events.RoomHeard
  alias Game.Format
  alias Game.Message
  alias Game.NPC
  alias Game.NPC.Actions
  alias Game.NPC.Events
  alias Game.Quest

  @doc """
  Parse the events for an NPC and update the struct
  """
  def parse_events(npc) do
    events =
      npc.events
      |> Enum.map(&Data.Events.parse/1)
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    %{npc | events: events}
  end

  @doc """
  Filter a list of events down to a single event type
  """
  def filter(events, event_type) do
    Enum.filter(events, fn event ->
      event.__struct__ == event_type
    end)
  end

  @doc """
  Calculate the total delay for an event
  """
  def calculate_total_delay(event) do
    event_delay(event) + actions_delay(event)
  end

  defp event_delay(event = %StateTicked{}) do
    minimum_delay = Map.get(event.options, :minimum_delay, 0)
    random_delay = Map.get(event.options, :random_delay, 0)

    minimum_delay = round(minimum_delay * 1000)
    random_delay = round(random_delay * 1000)

    case random_delay == 0 do
      true ->
        minimum_delay

      false ->
        minimum_delay + :rand.uniform(random_delay)
    end
  end

  defp event_delay(_event), do: 0

  defp actions_delay(event) do
    event.actions
    |> Enum.map(&Actions.calculate_total_delay/1)
    |> Enum.sum()
  end

  @doc """
  Instantiate events and start their ticking
  """
  def start_tick_events(state) do
    already_ticking_ids = Enum.map(state.tick_events, & &1.id)
    events = filter(state.events, StateTicked)

    events
    |> Enum.reject(fn event ->
      event.id in already_ticking_ids
    end)
    |> Enum.each(&delay_event/1)

    %{state | tick_events: events}
  end

  @doc """
  Calculate a delay and `:erlang.send_after/3` the event

  `{:tick, id}` is the message.
  """
  def delay_event(tick_event) do
    delay = calculate_total_delay(tick_event)
    Process.send_after(self(), {:tick, tick_event.id}, delay)
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

  def act_on(state, {"combat/ticked"}) do
    broadcast(state.npc, "combat/ticked")
    Events.CombatTicked.process(state)
    :ok
  end

  def act_on(state = %{npc: npc}, {"item/receive", character, instance}) do
    broadcast(npc, "item/receive", %{
      from: who(character),
      item: instance.id
    })

    state |> act_on_item_receive(character, instance)
  end

  def act_on(state, sent_event = %RoomEntered{character: character}) do
    broadcast(state.npc, "room/entered", who(character))
    Events.RoomEntered.process(state, sent_event)
    :ok
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

  def act_on(state, sent_event = %RoomHeard{message: message}) do
    broadcast(state.npc, "room/heard", %{
      type: message.type,
      name: message.sender.name,
      message: message.message,
      formatted: message.formatted
    })

    Events.RoomHeard.process(state, sent_event)

    :ok
  end

  def act_on(state = %{npc: npc}, {"quest/completed", player, quest}) do
    broadcast(npc, "quest/completed", %{
      player: %{id: player.id, name: player.name},
      quest: %{id: quest.id}
    })

    message = Message.npc_tell(npc, Format.resources(quest.completed_message))
    Channel.tell({:player, player}, npc(state), message)

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
  Act on the `item/receive` event
  """
  def act_on_item_receive(state, character, item_instance)

  def act_on_item_receive(state, {:player, player}, item_instance) do
    npc = %{state.npc | id: state.npc.original_id}
    Quest.track_progress(player, {:item, item_instance, npc})
    :ok
  end

  def act_on_item_receive(state, _, _), do: state

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

  def broadcast(%{id: id}, event, message) do
    :telemetry.execute([:exventure, :npc, :event, :acted], 1, %{event: event})
    Web.Endpoint.broadcast("npc:#{id}", event, message)
  end

  def who({:npc, npc}), do: %{type: :npc, name: npc.name}
  def who({:player, player}), do: %{type: :player, name: player.name}

  def npc(%{npc: npc, status: status}) when status != nil do
    {:npc, %{npc | status_line: status.line, status_listen: status.listen}}
  end

  def npc(%{npc: npc}), do: {:npc, npc}

  def notify_delayed(action, delayed) do
    :erlang.send_after(delayed, self(), {:"$gen_cast", {:notify, action}})
  end
end
