defmodule Web.Admin.ItemController do
  use Web.AdminController

  alias Web.Item

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: items, pagination: pagination} = Item.all(page: page, per: per)
    conn |> render("index.html", items: items, pagination: pagination)
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
