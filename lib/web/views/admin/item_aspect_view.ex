defmodule Web.Admin.ItemAspectView do
  use Web, :view

  alias Data.Item
  alias Data.Stats
  alias Ecto.Changeset
  alias Web.Admin.SharedView

  import Web.JSONHelper

  def types(), do: Item.types()

  def effects(changeset) do
    case Changeset.get_field(changeset, :effects) do
      nil ->
        []

      effects ->
        effects
    end
  end
end
