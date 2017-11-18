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
    action = for {key, val} <- event.action, into: %{}, do: {String.to_atom(key), val}
    event = %{event | action: action}
    {:ok, event}
  end

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @doc """
  Get a starting event, to fill out in the web interface. Just the structure,
  the values won't mean anyhting.
  """
  @spec starting_event(type :: String.t()) :: t()
  def starting_event("combat/tick") do
    %{type: "combat/tick", action: %{type: "target/effects", effects: [], delay: 1.5}}
  end
  def starting_event("room/entered") do
    %{type: "room/entered", action: %{type: "say", message: "Welcome!"}}
  end
  def starting_event("room/heard") do
    %{type: "room/heard", condition: %{regex: "hello"}, action: %{type: "say", message: "Welcome!"}}
  end

  @doc """
  Validate an event based on type

      iex> Data.Event.valid?(%{type: "combat/tick", action: %{type: "target/effects", effects: [], delay: 1.5}})
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
  """
  @spec valid?(event :: t) :: boolean
  def valid?(event)
  def valid?(event = %{type: "combat/tick"}) do
    keys(event) == [:action, :type]
      && valid_action_for_type?(event)
      && valid_action?(event.action)
  end
  def valid?(event = %{type: "room/entered"}) do
    keys(event) == [:action, :type]
      && valid_action_for_type?(event)
      && valid_action?(event.action)
  end
  def valid?(event = %{type: "room/heard"}) do
    keys(event) == [:action, :condition, :type]
      && valid_condition?(event.condition)
      && valid_action_for_type?(event)
      && valid_action?(event.action)
  end
  def valid?(_), do: false

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
  """
  def valid_action_for_type?(%{type: "combat/tick", action: action}), do: action.type in ["target/effects"]
  def valid_action_for_type?(%{type: "room/entered", action: action}), do: action.type in ["say", "target"]
  def valid_action_for_type?(%{type: "room/heard", action: action}), do: action.type in ["say"]
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

      iex> Data.Event.valid_action?(%{type: "say", message: "hi"})
      true

      iex> Data.Event.valid_action?(%{type: "target"})
      true

      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: []})
      true
      iex> effect = %{kind: "damage", type: :slashing, amount: 10}
      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [effect]})
      true
      iex> Data.Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [%{}]})
      false

      iex> Data.Event.valid_action?(%{type: "leave"})
      false
  """
  def valid_action?(%{type: "say", message: string}) when is_binary(string), do: true
  def valid_action?(%{type: "target"}), do: true
  def valid_action?(%{type: "target/effects", delay: delay, effects: effects}) when is_float(delay) do
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
