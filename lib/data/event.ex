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

      iex> Data.Event.load(%{"type" => "room/entered", "action" => %{"type" => "say", "message" => "Welcome!"}})
      {:ok, %{type: "room/entered", action: %{type: "say", message: "Welcome!"}}}
  """
  @impl Ecto.Type
  def load(event) do
    event = for {key, val} <- event, into: %{}, do: {String.to_atom(key), val}
    event = load_condition(event)
    action = for {key, val} <- event.action, into: %{}, do: {String.to_atom(key), val}
    action = load_action(action)
    event = %{event | action: action}
    {:ok, event}
  end

  defp load_condition(event = %{condition: condition}) when condition != nil do
    condition = for {key, val} <- event.condition, into: %{}, do: {String.to_atom(key), val}
    %{event | condition: condition}
  end
  defp load_condition(event), do: event

  defp load_action(action = %{type: "target/effects"}) do
    effects =
      action.effects
      |> Enum.map(fn (effect) ->
        case Effect.load(effect) do
          {:ok, effect} -> effect
          _ -> effect
        end
      end)
    %{action | effects: effects}
  end
  defp load_action(action), do: action

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @doc """
  Get a starting event, to fill out in the web interface. Just the structure,
  the values won't mean anyhting.
  """
  @spec starting_event(type :: String.t()) :: t()
  def starting_event("combat/tick") do
    %{type: "combat/tick", action: %{type: "target/effects", effects: [], delay: 1.5, text: ""}}
  end
  def starting_event("room/entered") do
    %{type: "room/entered", action: %{type: "say", message: "Welcome!"}}
  end
  def starting_event("room/heard") do
    %{type: "room/heard", condition: %{regex: "hello"}, action: %{type: "say", message: "Welcome!"}}
  end

  @doc """
  Validate an event based on type

      iex> Data.Event.valid?(%{type: "combat/tick", action: %{type: "target/effects", effects: [], delay: 1.5, text: ""}})
      true
      iex> Data.Event.valid?(%{type: "combat/tick", action: %{type: "target/effects", effects: :invalid}})
      false

      iex> Data.Event.valid?(%{type: "room/entered", action: %{type: "say", message: "hi"}})
      true
      iex> Data.Event.valid?(%{type: "room/entered", action: %{type: "say", message: :invalid}})
      false

      iex> Data.Event.valid?(%{type: "room/heard", condition: %{regex: "hello"}, action: %{type: "say", message: "hi"}})
      true
      iex> Data.Event.valid?(%{type: "room/heard", condition: nil, action: %{type: "say", message: "hi"}})
      false
      iex> Data.Event.valid?(%{type: "room/heard", condition: %{regex: "hello"}, action: %{type: "say", message: nil}})
      false

      iex> Data.Event.valid?(%{type: "tick", action: %{type: "move", max_distance: 3, chance: 50}})
      true
      iex> Data.Event.valid?(%{type: "tick", action: %{type: "move"}})
      false
  """
  @spec valid?(event :: t) :: boolean
  def valid?(event) do
    keys(event) == valid_keys(event.type)
      && valid_action_for_type?(event)
      && valid_action?(event.action)
  end

  defp valid_keys("room/heard"), do: [:action, :condition, :type]
  defp valid_keys(_type), do: [:action, :type]

  @doc """
  Validate the action matches the type

      iex> Data.Event.valid_action_for_type?(%{type: "combat/tick", action: %{type: "target/effects"}})
      true
      iex> Data.Event.valid_action_for_type?(%{type: "combat/tick", action: %{type: "leave"}})
      false

      iex> Data.Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "say"}})
      true
      iex> Data.Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "target"}})
      true
      iex> Data.Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "leave"}})
      false

      iex> Data.Event.valid_action_for_type?(%{type: "room/heard", action: %{type: "say"}})
      true
      iex> Data.Event.valid_action_for_type?(%{type: "room/heard", action: %{type: "leave"}})
      false

      iex> Data.Event.valid_action_for_type?(%{type: "tick", action: %{type: "move"}})
      true
      iex> Data.Event.valid_action_for_type?(%{type: "tick", action: %{type: "leave"}})
      false
  """
  def valid_action_for_type?(%{type: "combat/tick", action: action}), do: action.type in ["target/effects"]
  def valid_action_for_type?(%{type: "room/entered", action: action}), do: action.type in ["say", "target"]
  def valid_action_for_type?(%{type: "room/heard", action: action}), do: action.type in ["say"]
  def valid_action_for_type?(%{type: "tick", action: action}), do: action.type in ["move"]
  def valid_action_for_type?(_), do: false

  @doc """
  Validate the arguments matches the action

      iex> Data.Event.valid_condition?(%{regex: "hello"})
      true

      iex> Data.Event.valid_condition?(nil)
      false
  """
  def valid_condition?(%{regex: string}) when is_binary(string), do: true
  def valid_condition?(_), do: false

  @doc """
  Validate the arguments matches the action

      iex> Data.Event.valid_action?(%{type: "move", max_distance: 3, chance: 50})
      true
      iex> Data.Event.valid_action?(%{type: "move", max_distance: 3, chance: 150})
      false

      iex> Data.Event.valid_action?(%{type: "say", message: "hi"})
      true

      iex> Data.Event.valid_action?(%{type: "target"})
      true

      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [], text: ""})
      true
      iex> effect = %{kind: "damage", type: :slashing, amount: 10}
      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [effect], text: ""})
      true
      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [%{}], text: ""})
      false

      iex> Data.Event.valid_action?(%{type: "leave"})
      false
  """
  def valid_action?(%{type: "move", max_distance: max_distance, chance: chance}) do
    is_integer(max_distance) && is_integer(chance) && chance < 100
  end
  def valid_action?(%{type: "say", message: string}) when is_binary(string), do: true
  def valid_action?(%{type: "target"}), do: true
  def valid_action?(%{type: "target/effects", text: text, delay: delay, effects: effects}) when is_binary(text) and is_float(delay) do
    Enum.all?(effects, &Effect.valid?/1)
  end
  def valid_action?(_), do: false

  @doc """
  Validate events of the NPC
  """
  @spec validate_events(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_events(changeset) do
    case get_change(changeset, :events) do
      nil -> changeset
      events -> _validate_events(changeset, events)
    end
  end

  defp _validate_events(changeset, events) do
    case events |> Enum.all?(&valid?/1) do
      true -> changeset
      false -> add_error(changeset, :events, "are invalid")
    end
  end
end
