defmodule Web.Admin.NPCScriptView do
  use Web, :view

  import Ecto.Changeset

  def script(changeset) do
    case get_field(changeset, :script) do
      nil ->
        ""

      script ->
        script |> Poison.encode!(pretty: true)
    end
  end
end
