
defmodule Web.Controller.RoomItemControllerTest do
  use Web.AuthConnCase

  setup do
    npc = create_npc()
    item = create_item()

    %{item: item, npc: npc}
  end

  test "add an item to an npc", %{conn: conn, npc: npc, item: item} do
    conn = post conn, npc_item_path(conn, :create, npc.id), npc_item: %{item_id: item.id, drop_rate: 10}
    assert html_response(conn, 302)
  end

  test "delete a npc item", %{conn: conn, npc: npc, item: item} do
    npc_item = create_npc_item(npc, item, %{drop_rate: 10})

    conn = delete conn, npc_item_path(conn, :delete, npc_item.id)

    assert html_response(conn, 302)
  end
end
