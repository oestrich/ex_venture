defmodule Game.Color do
  @moduledoc """
  Format colors

  Replaces "{black}{/black}" with ANSII escape codes for the color
  """

  alias Game.ColorCodes

  @color_regex ~r/{\/?[\w:-]+}/

  def color_regex(), do: @color_regex

  @doc """
  For commands coming in from a player, delink them so they are only color.
  """
  def delink_commands(string) do
    string
    |> String.replace(~r/{command( send='.*')?}/i, "{command click=false}")
    |> String.replace(~r/{link}/i, "{link click=false}")
  end

  @doc """
  Format a string for colors
  """
  @spec format(String.t(), map()) :: String.t()
  def format(string, config \\ %{}) do
    with {:ok, ast} <- VML.parse(string) do
      colorize(ast, config)
    else
      _ ->
        string
    end
  end

  @doc """
  Colorize a VML AST
  """
  def colorize(string, config, current_color \\ "reset")

  def colorize(string, _config, _current_color) when is_binary(string), do: string

  def colorize(integer, _config, _current_color) when is_integer(integer), do: to_string(integer)

  def colorize(float, _config, _current_color) when is_float(float), do: to_string(float)

  def colorize(atom, _config, _current_color) when is_atom(atom), do: to_string(atom)

  def colorize({:tag, attributes, nodes}, config, current_color) do
    name = Keyword.get(attributes, :name)
    color = format_color(name, config)
    color <> colorize(nodes, config, name) <> format_color(current_color, config)
  end

  def colorize({:string, string}, _config, _current_color) do
    string
    |> String.replace("\\[", "[")
    |> String.replace("\\]", "]")
    |> String.replace("\\{", "{")
    |> String.replace("\\}", "}")
  end

  def colorize(list, config, current_color) when is_list(list) do
    list
    |> Enum.map(&colorize(&1, config, current_color))
    |> Enum.join()
  end

  @doc """
  Strip extra attributes from command color tags.

  Used for going out via the telnet client. Should not be used outside of this module.
  """
  @spec strip_commands(String.t()) :: String.t()
  def strip_commands(string) do
    string
    |> String.replace(~r/{command send='.*'}/, "{command}")
    |> String.replace(~r/{command click=false}/, "{command}")
    |> String.replace(~r/{link click=false}/, "{link}")
    |> String.replace(~r/{exit click=false}/, "{exit}")
  end

  @doc """
  Format a specific color tag
  """
  @spec format_color(String.t(), map()) :: String.t()
  def format_color(tag, config) do
    case format_semantic_color(tag) do
      :error ->
        format_basic_color(tag)

      {tag, color} ->
        color = Map.get(config, String.to_atom("color_#{tag}"), color)
        format_basic_color(to_string(color))
    end
  end

  def format_semantic_color("npc"), do: {:npc, :yellow}
  def format_semantic_color("item"), do: {:item, :cyan}
  def format_semantic_color("player"), do: {:player, :blue}
  def format_semantic_color("skill"), do: {:skill, :white}
  def format_semantic_color("quest"), do: {:quest, :yellow}
  def format_semantic_color("room"), do: {:room, :green}
  def format_semantic_color("zone"), do: {:zone, :white}
  def format_semantic_color("say"), do: {:say, :green}
  def format_semantic_color("link"), do: {:link, :white}
  def format_semantic_color("command"), do: {:command, :white}
  def format_semantic_color("exit"), do: {:exit, :white}
  def format_semantic_color("shop"), do: {:shop, :magenta}
  def format_semantic_color("hint"), do: {:hint, :cyan}
  def format_semantic_color("error"), do: {:error, :red}
  def format_semantic_color(_), do: :error

  @doc """
  Format a basic color tag, straight colors
  """
  @spec format_basic_color(String.t()) :: String.t()
  def format_basic_color("reset"), do: "\e[0m"

  def format_basic_color("black"), do: "\e[30m"
  def format_basic_color("red"), do: "\e[31m"
  def format_basic_color("green"), do: "\e[32m"
  def format_basic_color("yellow"), do: "\e[33m"
  def format_basic_color("blue"), do: "\e[34m"
  def format_basic_color("magenta"), do: "\e[35m"
  def format_basic_color("cyan"), do: "\e[36m"
  def format_basic_color("white"), do: "\e[37m"
  def format_basic_color("brown"), do: "\e[38;5;94m"
  def format_basic_color("dark-green"), do: "\e[38;5;22m"
  def format_basic_color("grey"), do: "\e[38;5;240m"
  def format_basic_color("light-grey"), do: "\e[38;5;250m"

  def format_basic_color(key) do
    key =
      key
      |> String.replace("{", "")
      |> String.replace("}", "")

    case ColorCodes.get(key) do
      {:ok, color_code} ->
        String.replace(color_code.ansi_escape, "\\e", "\e")

      {:error, :not_found} ->
        "\e[0m"
    end
  end

  @doc """
  Strip color information from a string

      iex> Game.Color.strip_color("{blue}Item{/blue}")
      "Item"

      iex> Game.Color.strip_color("{command send='help item'}Item{/command}")
      "Item"
  """
  @spec strip_color(String.t()) :: String.t()
  def strip_color(string) do
    string
    |> strip_commands()
    |> String.replace(~r/{\/?[\w-]+}/, "")
  end
end
