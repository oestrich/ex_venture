defmodule Web.Admin.RoomView do
  use Web, :view

  alias ExVenture.Rooms
  alias Web.FormView

  def override_value(assigns, field) do
    changeset = Map.get(assigns, :changeset)
    Map.get(assigns, field) || Ecto.Changeset.get_field(changeset, field)
  end
end
