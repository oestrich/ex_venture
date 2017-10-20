defmodule Web.Admin.ItemTaggingControllerTest do
  use Web.AuthConnCase

  alias Web.ItemTagging

  setup do
    item = create_item()
    item_tag = create_item_tag()
    %{item: item, item_tag: item_tag}
  end

  test "create an item tagging", %{conn: conn, item: item, item_tag: item_tag} do
    params = %{
      "item_tag_id" => item_tag.id,
    }

    conn = post conn, item_tagging_path(conn, :create, item.id), item_tagging: params
    assert html_response(conn, 302)
  end

  test "delete item tagging", %{conn: conn, item: item, item_tag: item_tag} do
    {:ok, item_tagging} = ItemTagging.create(item, item_tag.id)

    conn = delete conn, item_tagging_path(conn, :delete, item_tagging.id)
    assert html_response(conn, 302)
  end
end
