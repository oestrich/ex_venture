defmodule Web.Admin.ItemTaggingController do
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

  def create(conn, %{"item_id" => item_id, "item_tagging" => %{"item_tag_id" => item_tag_id}}) do
    item = Item.get(item_id)
    case ItemTagging.create(item, item_tag_id) do
      {:ok, item_tagging} -> conn |> redirect(to: item_path(conn, :show, item_tagging.item_id))
      {:error, changeset} ->
        item_tags = ItemTag.all()
        conn |> render("new.html", item: item, item_tags: item_tags, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item_tagging = ItemTagging.get(id)
    case ItemTagging.delete(item_tagging) do
      {:ok, _} -> conn |> redirect(to: item_path(conn, :show, item_tagging.item_id))
      _ -> conn |> redirect(to: item_path(conn, :show, item_tagging.item_id))
    end
  end
end
