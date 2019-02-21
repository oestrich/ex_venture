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

  def target_name(npc = %{type: "npc"}), do: npc_name(npc)

  def target_name(player = %{type: "player"}), do: player_name(player)

  def target_name({:npc, npc}), do: npc_name(npc)

  def target_name({:player, player}), do: player_name(player)

  def room_name(room), do: Rooms.room_name(room)

  def zone_name(zone), do: Rooms.zone_name(zone)

  @doc """
  Template a string

      iex> Game.Format.template(%Context{assigns: %{name: "Player"}}, "[name] says hello")
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
end
