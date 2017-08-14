defmodule Data.Stats do
  @moduledoc """
  Item statistics
  """

  import Data.Type

  @type character :: %{
    health: integer,
    strength: integer,
    dexterity: integer,
  }
  @type armor :: %{
    slot: :atom,
  }
  @type weapon :: %{
    damage_type: :atom,
  }

  @behaviour Ecto.Type

  def type, do: :map

  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  def load(stats) do
    stats = for {key, val} <- stats, into: %{}, do: {String.to_atom(key), val}
    stats = stats |> Enum.map(&cast_val/1) |> Enum.into(%{})
    {:ok, stats}
  end

  defp cast_val({key, val}) do
    case key do
      :slot ->
        {key, String.to_atom(val)}
      _ ->
        {key, val}
    end
  end

  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @doc """
  Slots on a character
  """
  @spec slots() :: [atom]
  def slots(), do: [:chest, :head]

  @doc """
  Fields in the statistics map
  """
  @spec fields() :: [atom]
  def fields(), do: [:dexterity, :health, :strength]

  @doc """
  Validate a character's stats

      iex> Data.Stats.valid_character?(%{health: 50, strength: 10, dexterity: 10})
      true

      iex> Data.Stats.valid_character?(%{health: 50, strength: 10, dexterity: :atom})
      false

      iex> Data.Stats.valid_character?(%{health: 50, strength: 10})
      false

      iex> Data.Stats.valid_character?(%{})
      false
  """
  @spec valid_character?(stats :: Stats.character) :: boolean
  def valid_character?(stats) do
    keys(stats) == fields()
      && is_integer(stats.dexterity)
      && is_integer(stats.health)
      && is_integer(stats.strength)
  end

  @doc """
  Validate an armor item

      iex> Data.Stats.valid_armor?(%{slot: :chest, armor: 10})
      true

      iex> Data.Stats.valid_armor?(%{slot: :chest, armor: :none})
      false

      iex> Data.Stats.valid_armor?(%{slot: :finger, armor: 10})
      false

      iex> Data.Stats.valid_armor?(%{})
      false
  """
  @spec valid_armor?(stats :: Stats.armor) :: boolean
  def valid_armor?(stats) do
    keys(stats) == [:armor, :slot] && valid_slot?(stats) && is_integer(stats.armor)
  end

  @doc """
  Validate a weapon item

      iex> Data.Stats.valid_weapon?(%{})
      true

      iex> Data.Stats.valid_weapon?(%{anything: true})
      false
  """
  @spec valid_weapon?(stats :: Stats.weapon) :: boolean
  def valid_weapon?(stats) do
    keys(stats) == []
  end

  @doc """
  Validate an item stats based on type

      iex> Data.Stats.valid?("basic", %{})
      true
      iex> Data.Stats.valid?("basic", %{slot: :chest})
      false
  """
  @spec valid?(type :: String.t, stats :: Stats.t) :: boolean
  def valid?(type, stats)
  def valid?("armor", stats) do
    valid_armor?(stats)
  end
  def valid?("weapon", stats) do
    valid_weapon?(stats)
  end
  def valid?("basic", stats) do
    keys(stats) == []
  end
  def valid?(_, _), do: false

  @doc """
  Validate if the slot is right

      iex> Data.Stats.valid_slot?(%{slot: :chest})
      true
      iex> Data.Stats.valid_slot?(%{slot: :finger})
      false
  """
  @spec valid_slot?(stats :: Stats.t) :: boolean
  def valid_slot?(stats)
  def valid_slot?(%{slot: slot}) do
    slot in slots()
  end

  @doc """
  Validate if the damage is right

      iex> Data.Stats.valid_damage?(%{damage_type: :slashing, damage: 10})
      true
      iex> Data.Stats.valid_damage?(%{damage_type: :slashing, damage: nil})
      false
      iex> Data.Stats.valid_damage?(%{damage_type: :finger})
      false
  """
  @spec valid_damage?(stats :: Stats.t) :: boolean
  def valid_damage?(stats)
  def valid_damage?(%{damage_type: damage_type, damage: damage}) do
    damage_type in [:slashing, :piercing, :bludgeoning] && is_integer(damage)
  end
  def valid_damage?(_), do: false
end
