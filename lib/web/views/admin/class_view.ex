defmodule Web.Admin.ClassView do
  use Web, :view

  alias Data.Stats
  alias Web.Admin.SharedView

  import Ecto.Changeset

  def each_level_stats(changeset) do
    case get_field(changeset, :each_level_stats) do
      nil -> %{} |> Stats.default() |> Poison.encode!(pretty: true)
      each_level_stats -> each_level_stats |> Stats.default() |> Poison.encode!(pretty: true)
    end
  end
end
