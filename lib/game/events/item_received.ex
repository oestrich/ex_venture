defmodule Game.Events.ItemReceived do
  @moduledoc """
  Event for receiving an item from another character
  """

  defstruct [:character, :instance, type: "item/received"]
end
