defmodule Web.Admin.FeatureView do
  use Web, :view

  alias Game.Format.Rooms, as: FormatRooms
  alias Web.Admin.SharedView
  alias Web.Color

  def tags(changeset) do
    case Ecto.Changeset.get_field(changeset, :tags) do
      nil ->
        ""

      tags ->
        tags |> Enum.join(", ")
    end
  end
end
