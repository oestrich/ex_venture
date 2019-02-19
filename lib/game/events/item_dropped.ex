defmodule Game.Events.ItemDropped do
  @moduledoc """
  Event for receiving an item from another character
  """

  defstruct [:character, :instance, type: "item/dropped"]
end
