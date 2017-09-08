
defmodule Web.Controller.RoomItemControllerTest do
  use Web.AuthConnCase

  setup do
    npc = create_npc()
    item = create_item()

    %{item: item, npc: npc}
  end

  test "add an item to an npc", %{conn: conn, npc: npc, item: item} do
    conn = post conn, npc_item_path(conn, :create, npc.id), item: %{id: item.id}
    assert html_response(conn, 302)
  end

  test "delete a npc item", %{conn: conn, npc: npc, item: item} do
    conn = delete conn, npc_item_path(conn, :delete, npc.id, item.id)
    assert html_response(conn, 302)
  end
end
