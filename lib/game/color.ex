defmodule Game.Color do
  @moduledoc """
  Format colors

  Replaces "{black}{/black}" with ANSII escape codes for the color
  """

  @doc """
  Format a string for colors
  """
  @spec format(String.t()) :: String.t()
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
    |> String.replace("{map:blue}", "\e[38;5;26m")
    |> String.replace("{map:brown}", "\e[38;5;94m")
    |> String.replace("{map:dark-green}", "\e[38;5;22m")
    |> String.replace("{map:green}", "\e[38;5;34m")
    |> String.replace("{map:grey}", "\e[38;5;247m")
    |> String.replace("{map:light-grey}", "\e[38;5;252m")
    |> String.replace(~r/{\/[\w:-]+}/, "\e[0m")
  end

  @doc """
  Strip color information from a string

      iex> Game.Color.strip_color("{blue}Item{/blue}")
      "Item"
  """
  @spec strip_color(String.t()) :: String.t()
  def strip_color(string) do
    string
    |> String.replace("{black}", "")
    |> String.replace("{red}", "")
    |> String.replace("{green}", "")
    |> String.replace("{yellow}", "")
    |> String.replace("{blue}", "")
    |> String.replace("{magenta}", "")
    |> String.replace("{cyan}", "")
    |> String.replace("{white}", "")
    |> String.replace(~r/{\/\w+}/, "")
  end
end
