defmodule Web.Admin.ItemAspectController do
  use Web.AdminController

  alias Web.ItemAspect

  def index(conn, _params) do
    item_aspects = ItemAspect.all()
    conn |> render("index.html", item_aspects: item_aspects)
  end

  def show(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    conn |> render("show.html", item_aspect: item_aspect)
  end

  def new(conn, _params) do
    changeset = ItemAspect.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"item_aspect" => params}) do
    case ItemAspect.create(params) do
      {:ok, item_aspect} -> conn |> redirect(to: item_aspect_path(conn, :show, item_aspect.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    changeset = ItemAspect.edit(item_aspect)
    conn |> render("edit.html", item_aspect: item_aspect, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item_aspect" => params}) do
    case ItemAspect.update(id, params) do
      {:ok, item_aspect} ->
        conn |> redirect(to: item_aspect_path(conn, :show, item_aspect.id))

      {:error, changeset} ->
        item_aspect = ItemAspect.get(id)
        conn |> render("edit.html", item_aspect: item_aspect, changeset: changeset)
    end
  end
end
