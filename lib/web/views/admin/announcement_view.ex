defmodule Web.Admin.AnnouncementView do
  use Web, :view

  alias Web.Admin.SharedView
  alias Web.TimeView

  import Ecto.Changeset, only: [get_field: 2]

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end
end
