defmodule Web.Admin.UserController do
  use Web.AdminController

  alias Web.User

  def index(conn, _params) do
    users = User.all()
    conn |> render("index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = User.get(id)
    conn |> render("show.html", user: user)
  end
end
