defmodule Web.Admin.ItemAspectControllerTest do
  use Web.AuthConnCase

  setup do
    item_aspect = create_item_aspect(%{name: "Swords"})
    %{item_aspect: item_aspect}
  end

  test "create an item aspect", %{conn: conn} do
    params = %{
      type: "armor",
      name: "Helmets",
      description: "A helmet",
      stats: ~s({"slot":"head","armor":10}),
      effects: ~s([{"kind":"stats","field":"strength","amount":10}]),
    }

    conn = post conn, item_aspect_path(conn, :create), item_aspect: params
    assert html_response(conn, 302)
  end

  test "update an item", %{conn: conn, item_aspect: item_aspect} do
    conn = put conn, item_aspect_path(conn, :update, item_aspect.id), item_aspect: %{name: "Short Sword"}
    assert redirected_to(conn) == item_aspect_path(conn, :show, item_aspect.id)
  end
end
