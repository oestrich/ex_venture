defmodule Test.DropCurrency do
  def uniform(_), do: 30
end

defmodule Test.NPCDelay do
  def uniform(_), do: 30
end

defmodule Test.ChanceSuccess do
  def uniform(_), do: 1
end

defmodule Test.ChanceFail do
  def uniform(_), do: 101
end
