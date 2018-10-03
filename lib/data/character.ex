defmodule Data.Character do
  @moduledoc """
  A user's character

  Should be used instead of their character as often as possible
  """

  defstruct [:id, :flags, :name, :save, :class, :race, :skill_ids]

  @doc """
  Create a character struct from a user
  """
  def from_user(user) do
    character = Map.take(user, [:id, :flags, :name, :save, :class, :race, :skill_ids])
    struct(__MODULE__, character)
  end
end
