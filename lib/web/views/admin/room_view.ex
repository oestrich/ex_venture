defmodule Web.Admin.RoomView do
  use Web, :view

  alias ExVenture.Rooms
  alias Web.FormView
  alias Web.PaginationView

  def override_value(assigns, field) do
    changeset = Map.get(assigns, :changeset)
    Map.get(assigns, field) || Ecto.Changeset.get_field(changeset, field)
  end

  def icon?(room) do
    not is_nil(room.map_icon)
  end
end
