defmodule Web.Admin.ConfigView do
  use Web, :view

  alias Ecto.Changeset
  alias Game.Config

  def name("after_sign_in_message"), do: "After Sign In Message"
  def name("basic_stats"), do: "Basic Stats"
  def name("character_names"), do: "Random Character Names"
  def name("game_name"), do: "Game Name"
  def name("motd"), do: "Message of the Day"
  def name("starting_save"), do: "Starting Save"

  def basic_stats_value(changeset) do
    changeset
    |> Changeset.get_field(:value, Config.basic_stats())
    |> Poison.decode!()
    |> Poison.encode!(pretty: true)
  end

  def starting_save_value(changeset) do
    changeset
    |> Changeset.get_field(:value)
    |> Poison.decode!()
    |> Poison.encode!(pretty: true)
  end
end
