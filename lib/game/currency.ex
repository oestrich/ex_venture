defmodule Game.Currency do
  @currency Application.get_env(:ex_venture, :game)[:currency]

  defmacro __using__(_opts) do
    quote do
      @currency Application.get_env(:ex_venture, :game)[:currency]

      import Game.Currency
    end
  end

  def currency(), do: @currency
end
