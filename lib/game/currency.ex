defmodule Game.Currency do
  @moduledoc """
  Helper module for currency

  Gives `@currency` and `currency/0`
  """

  @currency Application.get_env(:ex_venture, :game)[:currency]

  @doc """
  Sets up `@currency` and imports `currency/0`
  """
  defmacro __using__(_opts) do
    quote do
      @currency Application.get_env(:ex_venture, :game)[:currency]

      import Game.Currency
    end
  end

  @doc """
  Get the currency name
  """
  @spec currency() :: String.t()
  def currency(), do: @currency
end
