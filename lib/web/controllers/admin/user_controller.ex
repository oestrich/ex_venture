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

  def disconnect(conn, _params) do
    case User.disconnect() do
      :ok -> conn |> redirect(to: dashboard_path(conn, :index))
    end
  end

  def reset(conn, %{"user_id" => id}) do
    case User.reset(id) do
      {:ok, user} ->
        conn |> redirect(to: user_path(conn, :show, user.id))
      {:error, _} ->
        conn |> redirect(to: user_path(conn, :show, id))
    end
  end
end
