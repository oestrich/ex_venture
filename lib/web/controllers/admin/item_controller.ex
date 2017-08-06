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
end
