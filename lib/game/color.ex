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
  end

  @doc """
  Format a string for colors
  """
  @spec format(String.t(), map()) :: String.t()
  def format(string, config \\ %{}) do
    string = string |> strip_commands()
    split = Regex.split(@color_regex, string, include_captures: true)

    split
    |> _format([], [], config)
    |> Enum.reverse()
    |> Enum.join()
  end

  defp _format([], lines, stack, _config) when length(stack) > 0, do: ["\e[0m" | lines]
  defp _format([], lines, _stack, _config), do: lines

  defp _format([head | tail], lines, stack, config) do
    case Regex.match?(@color_regex, head) do
      true ->
        {code, stack} = format_color_code(head, stack, config)
        _format(tail, [code | lines], stack, config)

      false ->
        _format(tail, [head | lines], stack, config)
    end
  end

  @doc """
  Strip extra attributes from command color tags. Used for going out via
  the telnet client.
  """
  @spec strip_commands(String.t()) :: String.t()
  def strip_commands(string) do
    string
    |> String.replace(~r/{command send='.*'}/, "{command}")
    |> String.replace(~r/{command click=false}/, "{command}")
    |> String.replace(~r/{exit click=false}/, "{exit}")
  end

  @doc """
  Determine if the color code is an open tag
  """
  @spec color_code_open?(String.t()) :: boolean()
  def color_code_open?("{/" <> _), do: false
  def color_code_open?(_), do: true

  @doc """
  Format a color code, opening will add to the stack, closing will read/pull off of the stack
  """
  def format_color_code(code, stack, config) do
    case color_code_open?(code) do
      false ->
        format_closing_code(stack, config)

      true ->
        {format_color(code, config), [code | stack]}
    end
  end

  @doc """
  Format the closing code, which pulls off of the stack
  """
  @spec format_closing_code([], map()) :: {String.t(), []}
  def format_closing_code([_previous | [previous | stack]], config) do
    {format_color(previous, config), [previous | stack]}
  end

  def format_closing_code([_previous | stack], _config) do
    {format_basic_color("{/color}"), stack}
  end

  def format_closing_code(stack, _config) do
    {format_basic_color("{/color}"), stack}
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
        color = Map.get(config, :"color_#{tag}", color)
        format_basic_color("{#{color}}")
    end
  end

  def format_semantic_color("{npc}"), do: {:npc, :yellow}
  def format_semantic_color("{item}"), do: {:item, :cyan}
  def format_semantic_color("{player}"), do: {:player, :blue}
  def format_semantic_color("{skill}"), do: {:skill, :white}
  def format_semantic_color("{quest}"), do: {:quest, :yellow}
  def format_semantic_color("{room}"), do: {:room, :green}
  def format_semantic_color("{say}"), do: {:say, :green}
  def format_semantic_color("{command}"), do: {:command, :white}
  def format_semantic_color("{exit}"), do: {:exit, :white}
  def format_semantic_color("{shop}"), do: {:shop, :magenta}
  def format_semantic_color("{hint}"), do: {:hint, :cyan}
  def format_semantic_color(_), do: :error

  @doc """
  Format a basic color tag, straight colors
  """
  @spec format_basic_color(String.t()) :: String.t()
  def format_basic_color("{/" <> _), do: "\e[0m"

  def format_basic_color("{black}"), do: "\e[30m"
  def format_basic_color("{red}"), do: "\e[31m"
  def format_basic_color("{green}"), do: "\e[32m"
  def format_basic_color("{yellow}"), do: "\e[33m"
  def format_basic_color("{blue}"), do: "\e[34m"
  def format_basic_color("{magenta}"), do: "\e[35m"
  def format_basic_color("{cyan}"), do: "\e[36m"
  def format_basic_color("{white}"), do: "\e[37m"
  def format_basic_color("{map:blue}"), do: "\e[38;5;26m"
  def format_basic_color("{map:brown}"), do: "\e[38;5;94m"
  def format_basic_color("{map:dark-green}"), do: "\e[38;5;22m"
  def format_basic_color("{map:green}"), do: "\e[38;5;34m"
  def format_basic_color("{map:grey}"), do: "\e[38;5;247m"
  def format_basic_color("{map:light-grey}"), do: "\e[38;5;252m"

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
