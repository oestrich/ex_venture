defmodule Web.Admin.QuestView do
  use Web, :view
  use Game.Currency

  alias Web.Admin.SharedView
  alias Web.NPC

  import Ecto.Changeset

  def script(changeset) do
    case get_field(changeset, :script) do
      nil -> [] |> Poison.encode!(pretty: true)
      script -> script |> Poison.encode!(pretty: true)
    end
  end
end
