defmodule Data.Event do
  @moduledoc """
  In game events that NPCs will be listening for

  Valid kinds of events:

  - "room/entered": When a character enters a room
  """

  import Data.Type
  import Ecto.Changeset

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

      iex> Data.Event.load(%{"type" => "room/entered", "action" => "say", "arguments" => ["Welcome!"]})
      {:ok, %{type: "room/entered", action: "say", arguments: ["Welcome!"]}}
  """
  @impl Ecto.Type
  def load(event) do
    event = for {key, val} <- event, into: %{}, do: {String.to_atom(key), val}
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
  def starting_event("room/entered") do
    %{type: "room/entered", action: "say", arguments: ["Welcome!"]}
  end
  def starting_event("room/heard") do
    %{type: "room/heard", condition: "hello", action: "say", arguments: ["Welcome!"]}
  end

  @doc """
  Validate an event based on type

      iex> Data.Event.valid?(%{type: "room/entered", action: "say", arguments: ["hi"]})
      true
      iex> Data.Event.valid?(%{type: "room/entered", action: "say", arguments: :invalid})
      false

      iex> Data.Event.valid?(%{type: "room/heard", condition: "hello", action: "say", arguments: ["hi"]})
      true
      iex> Data.Event.valid?(%{type: "room/heard", condition: nil, action: "say", arguments: ["hi"]})
      false
      iex> Data.Event.valid?(%{type: "room/heard", action: "say", arguments: :invalid})
      false
  """
  @spec valid?(event :: t) :: boolean
  def valid?(event)
  def valid?(event = %{type: "room/entered"}) do
    keys(event) == [:action, :arguments, :type]
      && valid_action?(event)
      && valid_arguments?(event)
  end
  def valid?(event = %{type: "room/heard"}) do
    keys(event) == [:action, :arguments, :condition, :type]
      && valid_action?(event)
      && valid_arguments?(event)
  end
  def valid?(_), do: false

  @doc """
  Validate the action matches the type

      iex> Data.Event.valid_action?(%{type: "room/entered", action: "say"})
      true
      iex> Data.Event.valid_action?(%{type: "room/entered", action: "leave"})
      false

      iex> Data.Event.valid_action?(%{type: "room/heard", action: "say"})
      true
      iex> Data.Event.valid_action?(%{type: "room/heard", action: "leave"})
      false
  """
  def valid_action?(%{type: "room/entered", action: action}), do: action in ["say"]
  def valid_action?(%{type: "room/heard", action: action}), do: action in ["say"]
  def valid_action?(_), do: false

  @doc """
  Validate the arguments matches the action

      iex> Data.Event.valid_arguments?(%{action: "say", arguments: ["hi"]})
      true

      iex> Data.Event.valid_arguments?(%{action: "leave", arguments: :invalid})
      false
  """
  def valid_arguments?(%{action: "say", arguments: [string]}) when is_binary(string), do: true
  def valid_arguments?(_), do: false

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
