defmodule Web.Admin.RoomFeatureView do
  use Web, :view

  def form_method(%{id: id}) when id != nil, do: "PUT"
  def form_method(_), do: "POST"
end
