defmodule Web.SessionController do
  use Web, :controller

  alias Game.Authentication

  def new(conn, _params) do
    conn |> render("new.html")
  end

  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case Authentication.find_and_validate(name, password) do
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid sign in")
        |> redirect(to: public_session_path(conn, :new))

      user ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: public_page_path(conn, :index))
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: public_page_path(conn, :index))
  end
end
