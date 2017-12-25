defmodule Web.Admin.ItemController do
  use Web.AdminController

  alias Web.Item

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "item", %{})
    %{page: items, pagination: pagination} = Item.all(filter: filter, page: page, per: per)
    conn |> render("index.html", items: items, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    item = Item.get(id)
    compiled_item = Data.Item.compile(item)
    conn |> render("show.html", item: item, compiled_item: compiled_item)
  end

  def edit(conn, %{"id" => id}) do
    item = Item.get(id)
    changeset = Item.edit(item)
    conn |> render("edit.html", item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => params}) do
    case Item.update(id, params) do
      {:ok, item} -> conn |> redirect(to: item_path(conn, :show, item.id))
      {:error, changeset} ->
        item = Item.get(id)
        conn |> render("edit.html", item: item, changeset: changeset)
    end
  end

  def new(conn, %{"clone_id" => clone_id}) do
    item = clone_id |> Item.get() |> Item.clone()
    changeset = Item.edit(item)
    conn |> render("new.html", changeset: changeset)
  end
  def new(conn, _params) do
    changeset = Item.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"item" => params}) do
    case Item.create(params) do
      {:ok, item} -> conn |> redirect(to: item_path(conn, :show, item.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end
end
