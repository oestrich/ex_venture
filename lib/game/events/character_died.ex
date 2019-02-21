defmodule Game.Events.CharacterDied do
  @moduledoc """
  Event for a character dying
  """

  defstruct [:character, :killer, type: "character/died"]
end
