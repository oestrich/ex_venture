defmodule Web.Admin.NoteView do
  use Web, :view

  import Ecto.Changeset

  alias Web.Admin.SharedView

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end
end
