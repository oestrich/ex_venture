defmodule Data.Effect do
  @moduledoc """
  In game effects such as damage

  Valid kinds of effects:

  - "damage": Does an amount of damage
  - "damage/type": Halves damage if the type does not align
  - "damage/over-time": Does damage over time
  - "recover": Heals an amount of health/skill/move points
  - "stats": Modify base stats for the player
  """

  import Data.Type
  import Ecto.Changeset

  alias Data.Effect
  alias Data.Stats
  alias Data.Stats.Damage

  @type t :: map

  @type damage :: %{
          type: atom,
          amount: integer
        }

  @type damage_type :: %{
          types: [atom]
        }

  @typedoc """
  Damage over time. Does damage every `every` milliseconds.
  """
  @type damage_over_time :: %{
          type: atom(),
          amount: integer(),
          every: integer(),
          count: integer()
        }

  @type heal :: %{
          amount: integer
        }

  @type recover :: %{
          type: atom(),
          amount: integer()
        }

  @type stats :: %{
          field: atom,
          amount: integer
        }

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  @doc """
  Load an effect from a stored map

  Cast it properly

      iex> Data.Effect.load(%{"kind" => "damage", "type" => "slashing", "amount" => 10})
      {:ok, %{kind: "damage", type: :slashing, amount: 10}}

      iex> Data.Effect.load(%{"kind" => "damage/type", "types" => ["slashing"]})
      {:ok, %{kind: "damage/type", types: [:slashing]}}

      iex> Data.Effect.load(%{"kind" => "damage/over-time", "type" => "slashing", "amount" => 10, "every" => 3})
      {:ok, %{kind: "damage/over-time", type: :slashing, amount: 10, every: 3}}

      iex> Data.Effect.load(%{"kind" => "stats", "field" => "dexterity"})
      {:ok, %{kind: "stats", field: :dexterity}}
  """
  @impl Ecto.Type
  def load(effect) do
    effect = for {key, val} <- effect, into: %{}, do: {String.to_atom(key), val}
    effect = effect.kind |> cast_vals(effect)
    {:ok, effect}
  end

  defp cast_vals("damage", effect) do
    effect |> Map.put(:type, String.to_atom(effect.type))
  end

  defp cast_vals("damage/type", effect) do
    types = Enum.map(effect.types, &String.to_atom/1)
    effect |> Map.put(:types, types)
  end

  defp cast_vals("damage/over-time", effect) do
    effect |> Map.put(:type, String.to_atom(effect.type))
  end

  defp cast_vals("heal", effect) do
    effect |> Map.put(:type, String.to_atom(effect.type))
  end

  defp cast_vals("stats", effect) do
    effect |> Map.put(:field, String.to_atom(effect.field))
  end

  defp cast_vals(_type, effect), do: effect

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @doc """
  Get a starting effect, to fill out in the web interface. Just the structure,
  the values won't mean anyhting.
  """
  @spec starting_effect(type :: String.t()) :: t()
  def starting_effect("damage") do
    %{kind: "damage", type: :slashing, amount: 0}
  end

  def starting_effect("damage/type") do
    %{kind: "damage/type", types: []}
  end

  def starting_effect("damage/over-time") do
    %{kind: "damage/over-time", type: :slashing, amount: 0, every: 10, count: 2}
  end

  def starting_effect("recover") do
    %{kind: "recover", type: "health", amount: 0}
  end

  def starting_effect("stats") do
    %{kind: "stats", field: :dexterity, amount: 0}
  end

  @doc """
  Validate an effect based on type

      iex> Data.Effect.valid?(%{kind: "damage", type: :slashing, amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "damage", type: :slashing, amount: :invalid})
      false

      iex> Data.Effect.valid?(%{kind: "damage/type", types: [:slashing]})
      true
      iex> Data.Effect.valid?(%{kind: "damage/type", types: [:something]})
      false

      iex> Data.Effect.valid?(%{kind: "damage/over-time", type: :slashing, amount: 10, every: 3, count: 3})
      true
      iex> Data.Effect.valid?(%{kind: "damage/over-time", type: :something, amount: 10, every: 3, count: 3})
      false

      iex> Data.Effect.valid?(%{kind: "recover", type: "skill", amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "recover", type: "skill", amount: :invalid})
      false

      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: :invalid})
      false
  """
  @spec valid?(effect :: Stats.t()) :: boolean
  def valid?(effect)

  def valid?(effect = %{kind: "damage"}) do
    keys(effect) == [:amount, :kind, :type] && valid_damage?(effect)
  end

  def valid?(effect = %{kind: "damage/type"}) do
    keys(effect) == [:kind, :types] && valid_damage_type?(effect)
  end

  def valid?(effect = %{kind: "damage/over-time"}) do
    keys(effect) == [:amount, :count, :every, :kind, :type] && valid_damage_over_time?(effect)
  end

  def valid?(effect = %{kind: "recover"}) do
    keys(effect) == [:amount, :kind, :type] && valid_recover?(effect)
  end

  def valid?(effect = %{kind: "stats"}) do
    keys(effect) == [:amount, :field, :kind] && valid_stats?(effect)
  end

  def valid?(_), do: false

  @doc """
  Validate if damage is right

      iex> Data.Effect.valid_damage?(%{type: :slashing, amount: 10})
      true

      iex> Data.Effect.valid_damage?(%{type: :slashing, amount: nil})
      false

      iex> Data.Effect.valid_damage?(%{type: :finger})
      false
  """
  @spec valid_damage?(effect :: Effect.t()) :: boolean
  def valid_damage?(effect)

  def valid_damage?(%{type: type, amount: amount}) do
    type in Damage.types() && is_integer(amount)
  end

  def valid_damage?(_), do: false

  @doc """
  Validate if damage/type is right

      iex> Data.Effect.valid_damage_type?(%{types: [:slashing]})
      true

      iex> Data.Effect.valid_damage_type?(%{types: [:anything]})
      false

      iex> Data.Effect.valid_damage_type?(%{types: :slashing})
      false
  """
  @spec valid_damage_type?(effect :: Effect.t()) :: boolean
  def valid_damage_type?(effect)

  def valid_damage_type?(%{types: types}) when is_list(types) do
    Enum.all?(types, &(&1 in Damage.types()))
  end

  def valid_damage_type?(_), do: false

  @doc """
  Validate if `damage/over-time` is right

      iex> Data.Effect.valid_damage_over_time?(%{type: :slashing, amount: 10, every: 3, count: 3})
      true

      iex> Data.Effect.valid_damage_over_time?(%{type: :anything, amount: 10, every: 3, count: 3})
      false

      iex> Data.Effect.valid_damage_over_time?(%{type: :slashing, amount: :ten, every: 3, count: 3})
      false

      iex> Data.Effect.valid_damage_over_time?(%{type: :slashing, amount: 10, every: :three, count: 3})
      false

      iex> Data.Effect.valid_damage_over_time?(%{type: :slashing, amount: 10, every: 3, count: :three})
      false
  """
  @spec valid_damage_over_time?(effect :: Effect.t()) :: boolean
  def valid_damage_over_time?(effect)

  def valid_damage_over_time?(%{type: type, amount: amount, every: every, count: count}) do
    type in Damage.types() && is_integer(amount) && is_integer(every) && every > 0 &&
      is_integer(count) && count > 0
  end

  def valid_damage_over_time?(_), do: false

  @doc """
  Validate if recover is right

      iex> Data.Effect.valid_recover?(%{type: "health", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "skill", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "move", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "skill", amount: :invalid})
      false
      iex> Data.Effect.valid_recover?(%{type: "other", amount: 10})
      false
  """
  @spec valid_recover?(effect :: Effect.t()) :: boolean
  def valid_recover?(effect)

  def valid_recover?(%{type: type, amount: amount}) do
    type in ["health", "skill", "move"] && is_integer(amount)
  end

  def valid_recover?(_), do: false

  @doc """
  Validate if the stats type is right

      iex> Data.Effect.valid_stats?(%{field: :strength, amount: 10})
      true

      iex> Data.Effect.valid_stats?(%{field: :strength, amount: nil})
      false

      iex> Data.Effect.valid_stats?(%{field: :head, amount: 10})
      false

      iex> Data.Effect.valid_stats?(%{field: :strength})
      false
  """
  @spec valid_stats?(effect :: Effect.t()) :: boolean
  def valid_stats?(effect)

  def valid_stats?(%{field: field, amount: amount}) do
    field in [:strength, :dexterity] && is_integer(amount)
  end

  def valid_stats?(_), do: false

  def validate_effects(changeset) do
    case changeset do
      %{changes: %{effects: effects}} when effects != nil ->
        _validate_effects(changeset)

      _ ->
        changeset
    end
  end

  defp _validate_effects(changeset = %{changes: %{effects: effects}}) do
    case effects |> Enum.all?(&Effect.valid?/1) do
      true -> changeset
      false -> add_error(changeset, :effects, "are invalid")
    end
  end

  @doc """
  Check if an effect is continuous or not

    iex> Data.Effect.continuous?(%{kind: "damage/over-time"})
    true

    iex> Data.Effect.continuous?(%{kind: "damage"})
    false
  """
  @spec continuous?(Effect.t()) :: boolean()
  def continuous?(effect)
  def continuous?(%{kind: "damage/over-time"}), do: true
  def continuous?(_), do: false

  @doc """
  Instantiate an effect by giving it an ID to track, for future callbacks
  """
  @spec instantiate(Effect.t()) :: boolean()
  def instantiate(effect) do
    effect |> Map.put(:id, UUID.uuid4())
  end
end
