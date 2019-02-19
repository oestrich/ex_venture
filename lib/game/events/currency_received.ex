defmodule Game.Events.CurrencyReceived do
  @moduledoc """
  Event struct for receiving currency
  """

  defstruct [:character, :amount, type: "currenct/received"]
end
