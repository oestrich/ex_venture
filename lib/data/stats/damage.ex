defmodule Data.Stats.Damage do
  @moduledoc """
  Damage functions
  """

  @magical_types [
    :arcane,
    :divine,
    :electric,
    :fire,
    :ice,
    :poison
  ]

  @physical_types [
    :bludgeoning,
    :piercing,
    :slashing
  ]

  @all_types @magical_types ++ @physical_types

  @doc """
  Damage types
  """
  @spec types() :: [atom]
  def types(), do: @all_types

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
  @spec physical?(atom()) :: boolean()
  def physical?(type)

  Enum.map(@physical_types, fn type ->
    def physical?(unquote(type)), do: true
  end)

  def physical?(_), do: false

  @doc """
  Return true if type is magical in nature

      iex> Data.Stats.Damage.magical?(:arcane)
      true

      iex> Data.Stats.Damage.magical?(:divine)
      true

      iex> Data.Stats.Damage.magical?(:electric)
      true

      iex> Data.Stats.Damage.magical?(:fire)
      true

      iex> Data.Stats.Damage.magical?(:ice)
      true

      iex> Data.Stats.Damage.magical?(:poison)
      true

      iex> Data.Stats.Damage.magical?(:anything)
      false
  """
  @spec magical?(atom()) :: boolean()
  def magical?(type)

  Enum.map(@magical_types, fn type ->
    def magical?(unquote(type)), do: true
  end)

  def magical?(_), do: false
end
