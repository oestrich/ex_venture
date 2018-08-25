defmodule Game.Character.Simple do
  @moduledoc """
  Simple version of a character

  Minimal data for accessing the full character
  """

  defstruct [:type, :id, :name, extra: %{}]

  @doc """
  Convert a user to the simple version
  """
  def from_user(user) do
    %__MODULE__{
      type: :user,
      id: user.id,
      name: user.name,
      extra: %{
        flags: user.flags,
        level: user.save.level,
        race: user.race.name,
        class: user.class.name,
      }
    }
  end
end
