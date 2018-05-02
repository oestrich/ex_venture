defmodule Web.Admin.ItemController do
  use Web.AdminController

  alias Web.Item

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "item", %{})
    %{page: items, pagination: pagination} = Item.all(filter: filter, page: page, per: per)

    conn
    |> assign(:items, items)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    item = Item.get(id)
    compiled_item = Data.Item.compile(item)

    conn
    |> assign(:item, item)
    |> assign(:compiled_item, compiled_item)
    |> render("show.html")
  end

  def edit(conn, %{"id" => id}) do
    item = Item.get(id)
    changeset = Item.edit(item)

    conn
    |> assign(:item, item)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "item" => params}) do
    case Item.update(id, params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "#{item.name} updated!")
        |> redirect(to: item_path(conn, :show, item.id))

      {:error, changeset} ->
        item = Item.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{item.name}. Please try again.")
        |> assign(:item, item)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def new(conn, %{"clone_id" => clone_id}) do
    item = clone_id |> Item.get() |> Item.clone()
    changeset = Item.edit(item)

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def new(conn, _params) do
    changeset = Item.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"item" => params}) do
    case Item.create(params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "#{item.name} created!")
        |> redirect(to: item_path(conn, :show, item.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the item. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end
end
