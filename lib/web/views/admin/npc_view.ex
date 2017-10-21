defmodule Web.Admin.NPCView do
  use Web, :view
  use Game.Currency

  alias Data.Stats

  import Ecto.Changeset

  def stats(changeset) do
    case get_field(changeset, :stats) do
      nil -> %{} |> Stats.default() |> Poison.encode!(pretty: true)
      stats -> stats |> Stats.default() |> Poison.encode!(pretty: true)
    end
  end

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end
end
