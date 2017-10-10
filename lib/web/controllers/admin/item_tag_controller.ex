defmodule Web.Admin.ItemTagController do
  use Web.AdminController

  alias Web.ItemTag

  def index(conn, _params) do
    item_tags = ItemTag.all()
    conn |> render("index.html", item_tags: item_tags)
  end

  def show(conn, %{"id" => id}) do
    item_tag = ItemTag.get(id)
    conn |> render("show.html", item_tag: item_tag)
  end

  def new(conn, _params) do
    changeset = ItemTag.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"item_tag" => params}) do
    case ItemTag.create(params) do
      {:ok, item_tag} -> conn |> redirect(to: item_tag_path(conn, :show, item_tag.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    item_tag = ItemTag.get(id)
    changeset = ItemTag.edit(item_tag)
    conn |> render("edit.html", item_tag: item_tag, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item_tag" => params}) do
    case ItemTag.update(id, params) do
      {:ok, item_tag} -> conn |> redirect(to: item_tag_path(conn, :show, item_tag.id))
      {:error, changeset} ->
        item_tag = ItemTag.get(id)
        conn |> render("edit.html", item_tag: item_tag, changeset: changeset)
    end
  end
end
