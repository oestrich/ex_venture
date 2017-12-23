defmodule Web.Admin.ItemAspectingControllerTest do
  use Web.AuthConnCase

  alias Web.ItemAspecting

  setup do
    item = create_item()
    item_aspect = create_item_aspect()
    %{item: item, item_aspect: item_aspect}
  end

  test "create an item aspecting", %{conn: conn, item: item, item_aspect: item_aspect} do
    params = %{
      "item_aspect_id" => item_aspect.id,
    }

    conn = post conn, item_aspecting_path(conn, :create, item.id), item_aspecting: params
    assert html_response(conn, 302)
  end

  test "delete item aspecting", %{conn: conn, item: item, item_aspect: item_aspect} do
    {:ok, item_aspecting} = ItemAspecting.create(item, %{item_aspect_id: item_aspect.id})

    conn = delete conn, item_aspecting_path(conn, :delete, item_aspecting.id)
    assert html_response(conn, 302)
  end
end
