defmodule Game.Color do
  def format(string) do
    string
    |> String.replace("{black}", "\e[30m")
    |> String.replace("{red}", "\e[31m")
    |> String.replace("{green}", "\e[32m")
    |> String.replace("{yellow}", "\e[33m")
    |> String.replace("{blue}", "\e[34m")
    |> String.replace("{magenta}", "\e[35m")
    |> String.replace("{cyan}", "\e[36m")
    |> String.replace("{white}", "\e[37m")
    |> String.replace(~r/{\/\w+}/, "\e[0m")
  end
end
