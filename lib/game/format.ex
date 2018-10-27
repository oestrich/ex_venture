defmodule Game.Format do
  @moduledoc """
  Format data into strings to send to the connected player
  """

  alias Game.Color
  alias Game.Format.Channels
  alias Game.Format.Items
  alias Game.Format.NPCs
  alias Game.Format.Players
  alias Game.Format.Resources
  alias Game.Format.Rooms
  alias Game.Format.Template
  alias Game.Format.Shops
  alias Game.Format.Skills

  def currency(currency), do: Items.currency(currency)

  def name(who), do: target_name(who)

  def channel_name(channel), do: Channels.channel_name(channel)

  def item_name(item), do: Items.item_name(item)

  def player_name(player), do: Players.player_name(player)

  def npc_name(npc), do: NPCs.npc_name(npc)

  def shop_name(shop), do: Shops.shop_name(shop)

  def skill_name(skill), do: Skills.skill_name(skill)

  def target_name({:npc, npc}), do: npc_name(npc)

  def target_name({:player, player}), do: player_name(player)

  def zone_name(zone), do: Rooms.zone_name(zone)

  @doc """
  Template a string

      iex> Game.Format.template(%{assigns: %{name: "Player"}}, "[name] says hello")
      "Player says hello"
  """
  def template(context, string) do
    Template.render(context, string)
  end

  @doc """
  Run through the resources parser
  """
  def resources(string) do
    Resources.parse(string)
  end

  @doc """
  Create an 'underline'

  Example:

      iex> Game.Format.underline("Room Name")
      "-------------"

      iex> Game.Format.underline("{player}Player{/player}")
      "----------"
  """
  def underline(nil), do: ""

  def underline(string) do
    1..(String.length(Color.strip_color(string)) + 4)
    |> Enum.map(fn _ -> "-" end)
    |> Enum.join("")
  end

  @doc """
  Wraps lines of text
  """
  @spec wrap(String.t()) :: String.t()
  def wrap(string) do
    string
    |> String.replace("\n", "{newline}")
    |> String.replace("\r", "")
    |> String.split(~r/( |{[^}]*})/, include_captures: true)
    |> _wrap("", "")
  end

  @doc """
  Wraps a list of text
  """
  @spec wrap_lines([String.t()]) :: String.t()
  def wrap_lines(lines) do
    lines
    |> Enum.join(" ")
    |> wrap()
  end

  defp _wrap([], line, string), do: join(string, line, "\n")

  defp _wrap(["{newline}" | left], line, string) do
    case string do
      "" ->
        _wrap(left, "", line)

      _ ->
        _wrap(left, "", Enum.join([string, line], "\n"))
    end
  end

  defp _wrap([word | left], line, string) do
    test_line = "#{line} #{word}" |> Color.strip_color() |> String.trim()

    case String.length(test_line) do
      len when len < 80 ->
        _wrap(left, join(line, word, ""), string)

      _ ->
        _wrap(left, word, join(string, String.trim(line), "\n"))
    end
  end

  defp join(str1, str2, joiner) do
    Enum.join([str1, str2] |> Enum.reject(&(&1 == "")), joiner)
  end
end
