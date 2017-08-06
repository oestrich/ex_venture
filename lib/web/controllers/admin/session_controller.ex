defmodule Web.Admin.SessionController do
  use Web, :controller

  plug :put_layout, "login.html"

  alias Game.Authentication

  def new(conn, _params) do
    conn |> render("new.html")
  end

  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case Authentication.find_and_validate(name, password) do
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid sign in")
        |> redirect(to: session_path(conn, :new))
      user ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
