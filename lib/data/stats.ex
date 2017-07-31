defmodule Data.Stats do
  @moduledoc """
  Item statistics
  """

  import Data.Type

  @type t :: %{
    slot: :atom,
    damage: :atom,
  }

  defstruct [:slot, :damage]

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

      iex> Data.Stats.valid?("armor", %Data.Stats{slot: :chest})
      true
      iex> Data.Stats.valid?("armor", %Data.Stats{slot: :finger})
      false
      iex> Data.Stats.valid?("armor", %Data.Stats{})
      false

      iex> Data.Stats.valid?("weapon", %Data.Stats{damage: :slashing})
      true
      iex> Data.Stats.valid?("weapon", %Data.Stats{damage: :finger})
      false
      iex> Data.Stats.valid?("weapon", %Data.Stats{})
      false

      iex> Data.Stats.valid?("basic", %Data.Stats{})
      true
      iex> Data.Stats.valid?("basic", %Data.Stats{slot: :chest})
      false
  """
  @spec valid?(type :: String.t, stats :: Stats.t) :: boolean
  def valid?(type, stats)
  def valid?("armor", stats) do
    keys(stats) == [:slot] && valid_slot?(stats)
  end
  def valid?("weapon", stats) do
    keys(stats) == [:damage] && valid_damage?(stats)
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

      iex> Data.Stats.valid_damage?(%{damage: :slashing})
      true
      iex> Data.Stats.valid_damage?(%{damage: :finger})
      false
  """
  @spec valid_damage?(stats :: Stats.t) :: boolean
  def valid_damage?(stats)
  def valid_damage?(%{damage: damage}) do
    damage in [:slashing, :piercing, :bludgeoning]
  end
end
