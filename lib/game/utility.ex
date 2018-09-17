defmodule Game.Utility do
  @moduledoc """
  Utility functions, such as common string matching
  """

  @doc """
  Determine if a lookup string matches the npc's name

  Checks the downcased name

  Example:

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "tree stand shop")
      true

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "tree sta")
      true

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "hole in the")
      false
  """
  @spec matches?(map(), String.t()) :: boolean()
  def matches?(string, lookup) when is_binary(string) do
    String.starts_with?(string |> String.downcase(), lookup |> String.downcase())
  end

  def matches?(struct, lookup), do: matches?(struct.name, lookup)

  @doc """
  Match a name at the start of a string

      iex> Game.Utility.name_matches?(%{name: "Guard Captain"}, "guard message")
      true

      iex> Game.Utility.name_matches?(%{name: "Guard Captain"}, "guard captain message")
      true

      iex> Game.Utility.name_matches?(%{name: "Guard Captain"}, "bandit message")
      false
  """
  @spec name_matches?(map(), String.t()) :: boolean()
  def name_matches?(%{name: name}, string) do
    name_match(String.split(name), string)
  end

  defp name_match([name], string), do: message_starts_with?(string, name)

  defp name_match([name | [second | pieces]], string) do
    case message_starts_with?(string, name) do
      true -> true
      false -> name_match(["#{name} #{second}" | pieces], string)
    end
  end

  defp message_starts_with?(message, name) do
    String.starts_with?(message |> String.downcase(), name |> String.downcase())
  end

  @doc """
  Remove the matching name from the string

      iex> Game.Utility.strip_leading_text("Guard Captain", "guard message")
      "message"

      iex> Game.Utility.strip_leading_text("Guard Captain", "guard captain message")
      "message"

      iex> Game.Utility.strip_leading_text("Guard Captain", "bandit message")
      "bandit message"
  """
  @spec strip_leading_text(String.t(), String.t()) :: boolean()
  def strip_leading_text(text_to_strip, string) do
    _strip_leading_text(String.split(text_to_strip), string)
  end

  defp _strip_leading_text([], string), do: string

  defp _strip_leading_text(pieces, string) do
    case message_starts_with?(string, pieces |> Enum.join(" ")) do
      true ->
        string
        |> String.replace(~r/^#{pieces |> Enum.join(" ")}/i, "")
        |> String.trim()

      false ->
        [_ | pieces] = pieces |> Enum.reverse()
        pieces = pieces |> Enum.reverse()
        _strip_leading_text(pieces, string)
    end
  end

  @doc """
  Remove the matching name from the string

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "guard message")
      "message"

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "guard captain message")
      "message"

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "bandit message")
      "bandit message"
  """
  @spec strip_name(map(), String.t()) :: boolean()
  def strip_name(%{name: name}, string) do
    strip_leading_text(name, string)
  end

  @doc """
  Check if a string is empty, `nil` or `""`

      iex> Game.Utility.empty_string?(nil)
      true

      iex> Game.Utility.empty_string?("")
      true

      iex> Game.Utility.empty_string?("Hello")
      false
  """
  @spec empty_string?(String.t() | nil) :: boolean()
  def empty_string?(string) do
    is_nil(string) || string == ""
  end
end
