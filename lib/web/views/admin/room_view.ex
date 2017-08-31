defmodule Web.Admin.RoomView do
  use Web, :view

  alias Web.Zone

  def room_select(%{rooms: rooms}) do
    rooms |> Enum.map(&({&1.name, &1.id}))
  end
end
