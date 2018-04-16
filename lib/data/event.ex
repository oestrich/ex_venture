defmodule Data.Event do
  @moduledoc """
  In game events that NPCs will be listening for

  Valid kinds of events:

  - "room/entered": When a character enters a room
  - "room/heard": When a character hears something in a room
  - "combat/tick": What the character will do during combat
  """

  import Data.Type
  import Ecto.Changeset

  alias Data.Effect
  alias Data.Type

  @type t :: map

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  @doc """
  Load an event from a stored map

  Cast it properly
  """
  @impl Ecto.Type
  def load(event) do
    event = for {key, val} <- event, into: %{}, do: {String.to_atom(key), val}

    event =
      event
      |> load_condition()
      |> load_action()
      |> ensure(:id, UUID.uuid4())

    {:ok, event}
  end

  defp load_condition(event = %{condition: condition}) when condition != nil do
    condition = for {key, val} <- event.condition, into: %{}, do: {String.to_atom(key), val}
    %{event | condition: condition}
  end

  defp load_condition(event), do: event

  defp load_action(event) do
    case event do
      %{action: action} when action != nil ->
        action = for {key, val} <- event.action, into: %{}, do: {String.to_atom(key), val}
        %{event | action: _load_action(action)}

      _ ->
        event
    end
  end

  defp _load_action(action = %{type: "target/effects"}) do
    effects =
      action.effects
      |> Enum.map(fn effect ->
        case Effect.load(effect) do
          {:ok, effect} -> effect
          _ -> effect
        end
      end)

    %{action | effects: effects}
  end

  defp _load_action(action = %{type: "emote"}) do
    case action do
      %{status: status} ->
        status = for {key, val} <- status, into: %{}, do: {String.to_atom(key), val}
        %{action | status: status}

      _ ->
        action
    end
  end

  defp _load_action(action), do: action

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @doc """
  Get a starting event, to fill out in the web interface. Just the structure,
  the values won't mean anyhting.
  """
  @spec starting_event(String.t()) :: t()
  def starting_event("combat/tick") do
    %{
      type: "combat/tick",
      action: %{type: "target/effects", effects: [], delay: 1.5, weight: 10, text: ""}
    }
  end

  def starting_event("room/entered") do
    %{type: "room/entered", action: %{type: "say", message: "Welcome!"}}
  end

  def starting_event("room/heard") do
    %{
      type: "room/heard",
      condition: %{regex: "hello"},
      action: %{type: "say", message: "Welcome!"}
    }
  end

  def starting_event("tick") do
    %{
      type: "tick",
      action: %{type: "move", max_distance: 3, chance: 25, wait: 10}
    }
  end

  @doc """
  Validate an event to get errors out of the validation
  """
  def validate_event(event) do
    event
    |> validate()
    |> validate_keys(required: valid_keys(event.type))
    |> validate_action_for_type()
    |> validate_event_action()
    |> validate_event_condition()
  end

  # alphabetical
  defp valid_keys("room/heard") do
    [:action, :condition, :id, :type]
  end

  defp valid_keys(_type) do
    [:action, :id, :type]
  end

  defp validate_action_for_type(changeset) do
    case valid_action_for_type?(changeset.data) do
      true ->
        changeset

      false ->
        Type.Changeset.add_error(changeset, :action, "invalid type for event")
    end
  end

  defp validate_event_action(changeset = %{data: event}) do
    type = Map.get(event, :type)
    action = Map.get(event, :action)

    case validate_action(type, action) do
      %{valid?: true} ->
        changeset

      action_changeset ->
        Enum.reduce(action_changeset.errors, changeset, fn {key, val}, changeset ->
          Type.Changeset.add_error(changeset, :action, "#{key}: #{Enum.join(val, ", ")}")
        end)
    end
  end

  defp validate_event_condition(changeset = %{data: event}) do
    case validate_condition(event) do
      %{valid?: true} ->
        changeset

      condition_changeset ->
        Enum.reduce(condition_changeset.errors, changeset, fn {key, val}, changeset ->
          Type.Changeset.add_error(changeset, :condition, "#{key}: #{Enum.join(val, ", ")}")
        end)
    end
  end

  @doc """
  Validate the action matches the type
  """
  @spec valid_action_for_type?(t()) :: boolean()
  def valid_action_for_type?(event = %{action: action}) do
    event.type
    |> valid_type_actions()
    |> Enum.member?(action.type)
  end

  def valid_action_for_type?(_), do: false

  defp valid_type_actions(type) do
    case type do
      "combat/tick" ->
        ["target/effects"]

      "room/entered" ->
        ["say", "say/random", "target"]

      "room/heard" ->
        ["say"]

      "tick" ->
        ["emote", "move", "say", "say/random"]

      _ ->
        []
    end
  end

  def valid_condition?(event) do
    validate_condition(event).valid?
  end

  @doc """
  Validate the arguments matches the action
  """
  def validate_condition(event) do
    case event.type do
      "room/heard" ->
        condition = Map.get(event, :condition, %{}) || %{}

        condition
        |> validate()
        |> validate_keys(required: [:regex])
        |> validate_values(&validate_condition_values/1)

      _ ->
        case !Map.has_key?(event, :condition) do
          true ->
            event
            |> validate()

          false ->
            event
            |> validate()
            |> Map.put(:valid?, false)
        end
    end
  end

  defp validate_condition_values({key, value}) do
    case key do
      :regex ->
        is_binary(value)

      _ ->
        false
    end
  end

  @doc """
  Validate the arguments matches the action
  """
  def validate_action(event_type, action) do
    case event_type do
      "tick" ->
        validate_tick_action(action)

      _ ->
        validate_action(action)
    end
  end

  #@spec valid_action?(String.t(), map()) :: boolean()
  #def valid_action?(event_type, action) do
  #  validate_action(event_type, action).valid?
  #end

  @doc """
  Validate tick actions
  """
  @spec validate_tick_action(map()) :: boolean()
  def validate_tick_action(action = %{type: "say"}) do
    action
    |> validate()
    |> validate_keys(required: [:chance, :message, :type, :wait])
    |> validate_values(&validate_say_action_values/1)
  end

  def validate_tick_action(action = %{type: "say/random"}) do
    action
    |> validate()
    |> validate_keys(required: [:chance, :messages, :type, :wait])
    |> validate_values(&validate_say_random_action_values/1)
  end

  def validate_tick_action(action = %{type: "emote"}) do
    validate_action(action)
  end

  def validate_tick_action(action = %{type: "move"}) do
    validate_action(action)
  end

  def validate_tick_action(action) do
    action
    |> validate()
    |> Map.put(:valid?, false)
  end

  @doc """
  Validate all other event type actions
  """
  @spec validate_action(map()) :: boolean()
  def validate_action(action = %{type: "emote"}) do
    action
    |> validate()
    |> validate_keys(required: [:message, :chance, :wait, :type], optional: [:status])
    |> validate_values(&validate_emote_action_values/1)
  end

  def validate_action(action = %{type: "move"}) do
    action
    |> validate()
    |> validate_keys(required: [:chance, :max_distance, :type, :wait])
    |> validate_values(&validate_move_action_values/1)
  end

  def validate_action(action = %{type: "say"}) do
    action
    |> validate()
    |> validate_keys(required: [:message, :type])
    |> validate_values(&validate_say_action_values/1)
  end

  def validate_action(action = %{type: "say/random"}) do
    action
    |> validate()
    |> validate_keys(required: [:messages, :type])
    |> validate_values(&validate_say_random_action_values/1)
  end

  def validate_action(action = %{type: "target"}) do
    action
    |> validate()
    |> validate_keys(required: [:type])
  end

  def validate_action(action = %{type: "target/effects"}) do
    action
    |> validate()
    |> validate_keys(required: [:delay, :effects, :weight, :text, :type])
    |> validate_values(&validate_target_effects_action_values/1)
  end

  def validate_action(action) do
    action
    |> validate()
    |> Map.put(:valid?, false)
  end

  defp validate_emote_action_values({key, value}) do
    case key do
      :chance ->
        is_integer(value)

      :message ->
        is_binary(value)

      :status ->
        valid_status?(value)

      :type ->
        value == "emote"

      :wait ->
        is_integer(value)

      _ ->
        false
    end
  end

  defp validate_move_action_values({key, value}) do
    case key do
      :max_distance ->
        is_integer(value)

      :chance ->
        is_integer(value)

      :type ->
        value == "move"

      :wait ->
        is_integer(value)

      _ ->
        false
    end
  end

  defp validate_say_action_values({key, value}) do
    case key do
      :message ->
        is_binary(value)

      :chance ->
        is_integer(value)

      :type ->
        value == "say"

      :wait ->
        is_integer(value)

      _ ->
        false
    end
  end

  defp validate_say_random_action_values({key, value}) do
    case key do
      :messages ->
        is_list(value) && length(value) > 0 && Enum.all?(value, &is_binary/1)

      :chance ->
        is_integer(value)

      :type ->
        value == "say/random"

      :wait ->
        is_integer(value)

      _ ->
        false
    end
  end

  defp validate_target_effects_action_values({key, value}) do
    case key do
      :delay ->
        is_float(value)

      :effects ->
        is_list(value) && Enum.all?(value, &Effect.valid?/1)

      :text ->
        is_binary(value)

      :type ->
        value == "target/effects"

      :weight ->
        is_integer(value)

      _ ->
        false
    end
  end

  @doc """
  Validate status changing attributes
  """
  @spec valid_status?(map()) :: boolean()
  def valid_status?(action) do
    case keys(action) do
      [:reset] ->
        action.reset

      keys ->
        :key in keys && Enum.all?(action, &validate_status_key_value/1)
    end
  end

  defp validate_status_key_value({key, value}) do
    case key do
      :key ->
        is_binary(value)

      :line ->
        is_binary(value)

      :listen ->
        is_binary(value)

      _ ->
        false
    end
  end

  @doc """
  Validate events of the NPC
  """
  @spec validate_events(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_events(changeset) do
    case get_change(changeset, :events) do
      nil -> changeset
      events -> _validate_events(changeset, events)
    end
  end

  defp _validate_events(changeset, events) do
    case events |> Enum.all?(&valid?/1) do
      true ->
        changeset

      false ->
        add_error(changeset, :events, "are invalid")
    end
  end

  @doc """
  Validate an event based on type
  """
  @spec valid?(t()) :: boolean
  def valid?(event) do
    validate_event(event).valid?
  end
end
