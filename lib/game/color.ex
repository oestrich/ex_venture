defmodule Game.Color do
  @moduledoc """
  Format colors

  Replaces "{black}{/black}" with ANSII escape codes for the color
  """

  @color_regex ~r/{\/?[\w:-]+}/

  @doc """
  Format a string for colors
  """
  @spec format(String.t()) :: String.t()
  def format(string) do
    split = Regex.split(@color_regex, string, include_captures: true)

    split
    |> _format([], [])
    |> Enum.reverse()
    |> Enum.join()
  end

  defp _format([], lines, stack) when length(stack) > 0, do: ["\e[0m" | lines]
  defp _format([], lines, _stack), do: lines

  defp _format([head | tail], lines, stack) do
    case Regex.match?(@color_regex, head) do
      true ->
        {code, stack} = format_color_code(head, stack)
        _format(tail, [code | lines], stack)

      false ->
        _format(tail, [head | lines], stack)
    end
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
  def format_color_code(code, stack) do
    case color_code_open?(code) do
      false ->
        format_closing_code(stack)

      true ->
        {format_color(code), [code | stack]}
    end
  end

  @doc """
  Format the closing code, which pulls off of the stack
  """
  @spec format_closing_code([]) :: {String.t(), []}
  def format_closing_code([_previous | [previous | stack]]) do
    {format_color(previous), [previous | stack]}
  end

  def format_closing_code([_previous | stack]) do
    {format_color("{/color}"), stack}
  end

  def format_closing_code(stack) do
    {format_color("{/color}"), stack}
  end

  @doc """
  Format a specific color tag
  """
  @spec format_color(String.t()) :: String.t()
  def format_color("{black}"), do: "\e[30m"
  def format_color("{red}"), do: "\e[31m"
  def format_color("{green}"), do: "\e[32m"
  def format_color("{yellow}"), do: "\e[33m"
  def format_color("{blue}"), do: "\e[34m"
  def format_color("{magenta}"), do: "\e[35m"
  def format_color("{cyan}"), do: "\e[36m"
  def format_color("{white}"), do: "\e[37m"
  def format_color("{map:blue}"), do: "\e[38;5;26m"
  def format_color("{map:brown}"), do: "\e[38;5;94m"
  def format_color("{map:dark-green}"), do: "\e[38;5;22m"
  def format_color("{map:green}"), do: "\e[38;5;34m"
  def format_color("{map:grey}"), do: "\e[38;5;247m"
  def format_color("{map:light-grey}"), do: "\e[38;5;252m"
  def format_color(_), do: "\e[0m"

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
