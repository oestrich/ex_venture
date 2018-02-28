defmodule Web.Admin.RoomFeatureView do
  use Web, :view

  alias Web.Help

  def form_method(%{id: id}) when id != nil, do: "PUT"
  def form_method(_), do: "POST"
end
