defmodule Web.Admin.QuestView do
  use Web, :view

  alias Web.Admin.SharedView
  alias Web.NPC

  import Ecto.Changeset

  def conversations(changeset) do
    case get_field(changeset, :conversations) do
      nil -> [] |> Poison.encode!(pretty: true)
      conversations -> conversations |> Poison.encode!(pretty: true)
    end
  end
end
