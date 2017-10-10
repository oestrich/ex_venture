defmodule Web.Admin.ItemTagControllerTest do
  use Web.AuthConnCase

  setup do
    item_tag = create_item_tag(%{name: "Swords"})
    %{item_tag: item_tag}
  end

  test "create an item tag", %{conn: conn} do
    params = %{
      type: "armor",
      name: "Helmets",
      description: "A helmet",
      stats: ~s({"slot":"head","armor":10}),
      effects: ~s([{"kind":"stats","field":"strength","amount":10}]),
    }

    conn = post conn, item_tag_path(conn, :create), item_tag: params
    assert html_response(conn, 302)
  end

  test "update an item", %{conn: conn, item_tag: item_tag} do
    conn = put conn, item_tag_path(conn, :update, item_tag.id), item_tag: %{name: "Short Sword"}
    assert redirected_to(conn) == item_tag_path(conn, :show, item_tag.id)
  end
end
