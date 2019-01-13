defmodule Web.Admin.CharacterView do
  use Web, :view

  import Web.TimeView

  alias Game.Format.Players, as: FormatPlayers
  alias Game.Items
  alias Web.Admin.SharedView
  alias Web.Class
  alias Web.Race
  alias Web.User

  def online?(character) do
    Enum.any?(User.connected_players(), &(&1.id == character.id))
  end

  def live(character) do
    Enum.find(User.connected_players(), &(&1.id == character.id))
  end

  def stat_display_name(stat) do
    stat
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
