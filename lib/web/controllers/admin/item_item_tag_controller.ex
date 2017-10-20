defmodule Web.Admin.ItemItemTagController do
  use Web.AdminController

  alias Web.Item
  alias Web.ItemTag
  alias Web.ItemTagging

  def new(conn, %{"item_id" => item_id}) do
    item = Item.get(item_id)
    item_tags = ItemTag.all()
    changeset = ItemTagging.new(item)
    conn |> render("new.html", item: item, item_tags: item_tags, changeset: changeset)
  end
end
