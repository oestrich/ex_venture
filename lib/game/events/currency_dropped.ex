defmodule Game.Events.CurrencyDropped do
  @moduledoc """
  Event struct for dropping currency
  """

  defstruct [:character, :amount, type: "currenct/dropped"]
end
