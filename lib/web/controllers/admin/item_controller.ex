defmodule Web.Admin.ItemController do
  use Web.AdminController

  alias Web.Item

  def index(conn, _params) do
    items = Item.all()
    conn |> render("index.html", items: items)
  end

  def show(conn, %{"id" => id}) do
    item = Item.get(id)
    conn |> render("show.html", item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Item.get(id)
    changeset = Item.edit(item)
    conn |> render("edit.html", item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => params}) do
    case Item.update(id, params) do
      {:ok, item} -> conn |> redirect(to: item_path(conn, :show, item.id))
      {:error, changeset} -> conn |> render("edit.html", changeset: changeset)
    end
  end
end
