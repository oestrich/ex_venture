defmodule Data.Character do
  @moduledoc """
  A user's character

  Should be used instead of their character as often as possible
  """

  defstruct [:id, :flags, :name, :save, :class, :race]

  @doc """
  Create a character struct from a user
  """
  def from_user(user) do
    character = Map.take(user, [:id, :flags, :name, :save, :class, :race])
    struct(__MODULE__, character)
  end
end
