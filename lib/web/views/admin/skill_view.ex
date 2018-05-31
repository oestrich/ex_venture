defmodule Web.Admin.SkillView do
  use Web, :view

  alias Web.Admin.SharedView

  import Ecto.Changeset

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end
end
