defmodule Web.Admin.UserController do
  use Web.AdminController

  plug Web.Plug.FetchPage when action in [:index]

  alias Web.User

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: users, pagination: pagination} = User.all(page: page, per: per)
    conn |> render("index.html", users: users, pagination: pagination)
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
