defmodule Web.Admin.RaceView do
  use Web, :view

  alias Data.Stats
  alias Game.Config

  import Ecto.Changeset

  def starting_stats(changeset) do
    case get_field(changeset, :starting_stats) do
      nil ->
        Config.basic_stats() |> Poison.encode!(pretty: true)

      starting_stats ->
        starting_stats |> Stats.default() |> Poison.encode!(pretty: true)
    end
  end
end
