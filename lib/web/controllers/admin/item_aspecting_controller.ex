defmodule Web.Admin.ItemAspectingController do
  use Web.AdminController

  alias Web.Item
  alias Web.ItemAspect
  alias Web.ItemAspecting

  def new(conn, %{"item_id" => item_id}) do
    item = Item.get(item_id)
    item_aspects = ItemAspect.all()
    changeset = ItemAspecting.new(item)

    conn
    |> assign(:item, item)
    |> assign(:item_aspects, item_aspects)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"item_id" => item_id, "item_aspecting" => params}) do
    item = Item.get(item_id)

    case ItemAspecting.create(item, params) do
      {:ok, item_aspecting} ->
        conn
        |> put_flash(:info, "Added the aspect to #{item.name}!")
        |> redirect(to: item_path(conn, :show, item_aspecting.item_id))

      {:error, changeset} ->
        item_aspects = ItemAspect.all()

        conn
        |> put_flash(
          :error,
          "There was an issue adding the item aspect to #{item.name}. Please try again."
        )
        |> assign(:item, item)
        |> assign(:item_aspects, item_aspects)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    item_aspect = ItemAspecting.get(id)

    case ItemAspecting.delete(item_aspect) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Aspect removed from the item")
        |> redirect(to: item_path(conn, :show, item_aspect.item_id))

      _ ->
        conn
        |> put_flash(
          :info,
          "There was an issue removing the aspect from the item. Please try again."
        )
        |> redirect(to: item_path(conn, :show, item_aspect.item_id))
    end
  end
end
