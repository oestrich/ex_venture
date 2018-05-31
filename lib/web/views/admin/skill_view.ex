defmodule Web.Admin.SkillView do
  use Web, :view

  alias Data.Effect
  alias Ecto.Changeset
  alias Web.Admin.SharedView

  import Ecto.Changeset

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end

  def effects(changeset) do
    case Changeset.get_field(changeset, :effects) do
      nil ->
        []

      effects ->
       effects
    end
  end
end
