defmodule Web.SessionController do
  use Web, :controller

  alias Web.User

  def new(conn, _params) do
    conn |> render("new.html")
  end

  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case User.find_and_validate(name, password) do
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid sign in")
        |> redirect(to: public_session_path(conn, :new))

      user ->
        conn
        |> put_session(:user_token, user.token)
        |> after_sign_in_redirect()
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: public_page_path(conn, :index))
  end

  defp after_sign_in_redirect(conn) do
    case get_session(conn, :last_path) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      path ->
        conn
        |> put_session(:last_path, nil)
        |> redirect(to: path)
    end
  end
end
