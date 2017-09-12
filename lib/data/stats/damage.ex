defmodule Data.Stats.Damage do
  @moduledoc """
  Damage functions
  """

  @doc """
  Damage types
  """
  @spec types() :: [atom]
  def types(), do: [:arcane, :fire, :ice, :slashing, :piercing, :bludgeoning]

  @doc """
  Return true if type is physical in nature

      iex> Data.Stats.Damage.physical?(:slashing)
      true

      iex> Data.Stats.Damage.physical?(:piercing)
      true

      iex> Data.Stats.Damage.physical?(:bludgeoning)
      true

      iex> Data.Stats.Damage.physical?(:anything)
      false
  """
  @spec physical?(type :: atom) :: boolean
  def physical?(type)
  def physical?(:slashing), do: true
  def physical?(:piercing), do: true
  def physical?(:bludgeoning), do: true
  def physical?(_), do: false

  @doc """
  Return true if type is magical in nature

      iex> Data.Stats.Damage.magical?(:arcane)
      true

      iex> Data.Stats.Damage.magical?(:fire)
      true

      iex> Data.Stats.Damage.magical?(:ice)
      true

      iex> Data.Stats.Damage.magical?(:anything)
      false
  """
  @spec magical?(type :: atom) :: boolean
  def magical?(type)
  def magical?(:arcane), do: true
  def magical?(:fire), do: true
  def magical?(:ice), do: true
  def magical?(_), do: false
end
