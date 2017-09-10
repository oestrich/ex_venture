defmodule Test.DropCurrency do
  def uniform(_), do: 30
end

defmodule Test.DropChanceSuccess do
  def uniform(_), do: 1
end

defmodule Test.DropChanceFail do
  def uniform(_), do: 101
end
