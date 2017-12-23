defmodule Web.Admin.ItemAspectingController do
  use Web.AdminController

  alias Web.Item
  alias Web.ItemAspect
  alias Web.ItemAspecting

  def new(conn, %{"item_id" => item_id}) do
    item = Item.get(item_id)
    item_aspects = ItemAspect.all()
    changeset = ItemAspecting.new(item)
    conn |> render("new.html", item: item, item_aspects: item_aspects, changeset: changeset)
  end

  def create(conn, %{"item_id" => item_id, "item_aspecting" => params}) do
    item = Item.get(item_id)
    case ItemAspecting.create(item, params) do
      {:ok, item_aspect} -> conn |> redirect(to: item_path(conn, :show, item_aspect.item_id))
      {:error, changeset} ->
        item_aspects = ItemAspect.all()
        conn |> render("new.html", item: item, item_aspects: item_aspects, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item_aspect = ItemAspecting.get(id)
    case ItemAspecting.delete(item_aspect) do
      {:ok, _} -> conn |> redirect(to: item_path(conn, :show, item_aspect.item_id))
      _ -> conn |> redirect(to: item_path(conn, :show, item_aspect.item_id))
    end
  end
end
