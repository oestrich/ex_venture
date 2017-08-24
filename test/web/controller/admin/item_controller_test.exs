defmodule Web.Admin.ItemControllerTest do
  use Web.AuthConnCase

  alias Game.Items

  setup do
    item = create_item(%{name: "Sword"})
    %{item: item}
  end

  test "create an item", %{conn: conn} do
    item = %{
      type: "armor",
      name: "Helmet",
      description: "A helmet",
      stats: ~s({"slot":"head","armor":10}),
      effects: ~s([{"kind":"stats","field":"strength","amount":10}]),
      keywords: "helmet",
    }

    conn = post conn, item_path(conn, :create), item: item
    assert html_response(conn, 302)
  end

  test "update an item", %{conn: conn, item: item} do
    conn = put conn, item_path(conn, :update, item.id), item: %{name: "Short Sword", keywords: "sword, short"}
    assert redirected_to(conn) == item_path(conn, :show, item.id)

    assert Items.item(item.id).name == "Short Sword"
    assert Items.item(item.id).keywords == ["sword", "short"]
  end
end
