defmodule Data.Effect do
  @moduledoc """
  In game effects such as damage

  Valid kinds of effects:

  - "damage": Does an amount of damage
  - "damage/type": Halves damage if the type does not align
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
    amount: integer,
  }

  @type damage_type :: %{
    types: [atom],
  }

  @type stats :: %{
    field: atom,
    amount: integer,
  }

  @behaviour Ecto.Type

  def type, do: :map

  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  @doc """
  Load an effect from a stored map

  Cast it properly

      iex> Data.Effect.load(%{"kind" => "damage", "type" => "slashing", "amount" => 10})
      {:ok, %{kind: "damage", type: :slashing, amount: 10}}

      iex> Data.Effect.load(%{"kind" => "damage/type", "types" => ["slashing"]})
      {:ok, %{kind: "damage/type", types: [:slashing]}}

      iex> Data.Effect.load(%{"kind" => "stats", "field" => "dexterity"})
      {:ok, %{kind: "stats", field: :dexterity}}
  """
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
  defp cast_vals("stats", effect) do
    effect |> Map.put(:field, String.to_atom(effect.field))
  end
  defp cast_vals(_type, effect), do: effect

  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

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

      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: :invalid})
      false
  """
  @spec valid?(effect :: Stats.t) :: boolean
  def valid?(effect)
  def valid?(effect = %{kind: "damage"}) do
    keys(effect) == [:amount, :kind, :type] && valid_damage?(effect)
  end
  def valid?(effect = %{kind: "damage/type"}) do
    keys(effect) == [:kind, :types] && valid_damage_type?(effect)
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
  @spec valid_damage?(effect :: Effect.t) :: boolean
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
  @spec valid_damage_type?(effect :: Effect.t) :: boolean
  def valid_damage_type?(effect)
  def valid_damage_type?(%{types: types}) when is_list(types) do
    Enum.all?(types, &(&1 in Damage.types()))
  end
  def valid_damage_type?(_), do: false

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
  @spec valid_stats?(effect :: Effect.t) :: boolean
  def valid_stats?(effect)
  def valid_stats?(%{field: field, amount: amount}) do
    field in [:strength, :dexterity] && is_integer(amount)
  end
  def valid_stats?(_), do: false

  def validate_effects(changeset) do
    case changeset do
      %{changes: %{effects: effects}} when effects != nil ->
        _validate_effects(changeset)
      _ -> changeset
    end
  end

  defp _validate_effects(changeset = %{changes: %{effects: effects}}) do
    case effects |> Enum.all?(&Effect.valid?/1) do
      true -> changeset
      false -> add_error(changeset, :effects, "are invalid")
    end
  end
end
