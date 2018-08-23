defmodule Web.Admin.UserView do
  use Web, :view

  import Ecto.Changeset
  import Web.TimeView

  alias Game.Format
  alias Game.Items
  alias Web.Admin.SharedView
  alias Web.Class
  alias Web.Race
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

  def command_name(command) do
    command
    |> String.split(".")
    |> List.last()
  end

  def checked_flag?(user, flag) do
    flag in user.flags
  end
end
