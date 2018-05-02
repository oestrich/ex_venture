defmodule Web.Admin.ItemAspectController do
  use Web.AdminController

  alias Web.ItemAspect

  def index(conn, _params) do
    item_aspects = ItemAspect.all()

    conn
    |> assign(:item_aspects, item_aspects)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)

    conn
    |> assign(:item_aspect, item_aspect)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = ItemAspect.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"item_aspect" => params}) do
    case ItemAspect.create(params) do
      {:ok, item_aspect} ->
        conn
        |> put_flash(:info, "Created #{item_aspect.name}!")
        |> redirect(to: item_aspect_path(conn, :show, item_aspect.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the item aspect. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    changeset = ItemAspect.edit(item_aspect)

    conn
    |> assign(:item_aspect, item_aspect)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "item_aspect" => params}) do
    case ItemAspect.update(id, params) do
      {:ok, item_aspect} ->
        conn
        |> put_flash(:info, "#{item_aspect.name} updated!")
        |> redirect(to: item_aspect_path(conn, :show, item_aspect.id))

      {:error, changeset} ->
        item_aspect = ItemAspect.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{item_aspect.name}. Please try again.")
        |> assign(:item_aspect, item_aspect)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
