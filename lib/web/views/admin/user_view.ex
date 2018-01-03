defmodule Web.Admin.UserView do
  use Web, :view

  alias Game.Format
  alias Game.Items
  alias Web.Admin.SharedView
  alias Web.Class
  alias Web.Race
  alias Web.User

  @timezone Application.get_env(:ex_venture, :timezone)

  def online?(user) do
    Enum.any?(User.connected_players(), &(&1.id == user.id))
  end

  def live(user) do
    Enum.find(User.connected_players(), &(&1.id == user.id))
  end

  def time(time) do
    new_york = Timex.Timezone.get(@timezone, Timex.now)

    time
    |> Timex.Timezone.convert(new_york)
    |> Timex.format!("%Y-%m-%d %I:%M %p", :strftime)
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
end
