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
  def matches?(struct, lookup) do
    String.starts_with?(struct.name |> String.downcase(), lookup |> String.downcase())
  end

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

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "guard message")
      "message"

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "guard captain message")
      "message"

      iex> Game.Utility.strip_name(%{name: "Guard Captain"}, "bandit message")
      "bandit message"
  """
  @spec strip_name(map(), String.t()) :: boolean()
  def strip_name(%{name: name}, string) do
    _strip_name(String.split(name), string)
  end

  defp _strip_name([], string), do: string

  defp _strip_name(pieces, string) do
    case message_starts_with?(string, pieces |> Enum.join(" ")) do
      true ->
        string
        |> String.replace(~r/^#{pieces |> Enum.join(" ")}/i, "")
        |> String.trim()

      false ->
        [_ | pieces] = pieces |> Enum.reverse()
        pieces = pieces |> Enum.reverse()
        _strip_name(pieces, string)
    end
  end
end
