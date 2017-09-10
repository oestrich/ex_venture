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

  def teleport(conn, %{"room_id" => room_id}) do
    %{user: user} = conn.assigns
    case User.teleport(user, room_id) do
      {:ok, _user} -> conn |> redirect(to: room_path(conn, :show, room_id))
      _ -> conn |> redirect(to: room_path(conn, :show, room_id))
    end
  end
end
