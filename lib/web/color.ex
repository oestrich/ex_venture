defmodule Web.Color do
  @moduledoc """
  Interface to the game color module
  """

  def options() do
    Game.Color.options()
    |> Enum.map(fn color ->
      {String.capitalize(color), color}
    end)
  end

  def format(string) do
    string
    |> String.replace("{black}", "<span class='black'>")
    |> String.replace("{red}", "<span class='red'>")
    |> String.replace("{green}", "<span class='green'>")
    |> String.replace("{yellow}", "<span class='yellow'>")
    |> String.replace("{blue}", "<span class='blue'>")
    |> String.replace("{magenta}", "<span class='magenta'>")
    |> String.replace("{cyan}", "<span class='cyan'>")
    |> String.replace("{white}", "<span class='white'>")
    |> String.replace("{map:blue}", "<span class='map-blue'>")
    |> String.replace("{map:brown}", "<span class='map-brown'>")
    |> String.replace("{map:dark-green}", "<span class='map-dark-green'>")
    |> String.replace("{map:green}", "<span class='map-green'>")
    |> String.replace("{map:grey}", "<span class='map-grey'>")
    |> String.replace("{map:light-grey}", "<span class='map-light-grey'>")
    |> String.replace("{npc}", "<span class='yellow'>")
    |> String.replace("{item}", "<span class='cyan'>")
    |> String.replace("{player}", "<span class='blue'>")
    |> String.replace("{skill}", "<span class='white'>")
    |> String.replace("{quest}", "<span class='yellow'>")
    |> String.replace("{room}", "<span class='green'>")
    |> String.replace("{say}", "<span class='green'>")
    |> String.replace("{command}", "<span class='white'>")
    |> String.replace("{exit}", "<span class='white'>")
    |> String.replace("{shop}", "<span class='magenta'>")
    |> String.replace("{shop}", "<span class='cyan'>")
    |> String.replace(~r/{\/[\w:-]+}/, "</span>")
  end
end
