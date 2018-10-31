defmodule Web.Admin.CharacterView do
  use Web, :view

  import Web.TimeView

  alias Game.Items
  alias Web.User

  def online?(user) do
    Enum.any?(User.connected_players(), &(&1.id == user.id))
  end

  def live(user) do
    Enum.find(User.connected_players(), &(&1.id == user.id))
  end

  def stat_display_name(stat) do
    stat
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
