defmodule Game.Currency do
  @moduledoc """
  Helper module for currency

  Gives `@currency` and `currency/0`
  """

  @currency Application.get_env(:ex_venture, :game)[:currency]

  defmacro __using__(_opts) do
    quote do
      @currency Application.get_env(:ex_venture, :game)[:currency]

      import Game.Currency
    end
  end

  def currency(), do: @currency
end
