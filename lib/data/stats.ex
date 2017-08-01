defmodule Data.Stats do
  @moduledoc """
  Item statistics
  """

  import Data.Type

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
  def slots(), do: [:chest]

  @doc """
  Validate an item stats based on type

      iex> Data.Stats.valid?("armor", %{slot: :chest})
      true
      iex> Data.Stats.valid?("armor", %{slot: :finger})
      false
      iex> Data.Stats.valid?("armor", %{})
      false

      iex> Data.Stats.valid?("weapon", %{damage_type: :slashing, damage: 10})
      true
      iex> Data.Stats.valid?("weapon", %{damage_type: :finger})
      false
      iex> Data.Stats.valid?("weapon", %{})
      false

      iex> Data.Stats.valid?("basic", %{})
      true
      iex> Data.Stats.valid?("basic", %{slot: :chest})
      false
  """
  @spec valid?(type :: String.t, stats :: Stats.t) :: boolean
  def valid?(type, stats)
  def valid?("armor", stats) do
    keys(stats) == [:slot] && valid_slot?(stats)
  end
  def valid?("weapon", stats) do
    keys(stats) == [:damage, :damage_type] && valid_damage?(stats)
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
