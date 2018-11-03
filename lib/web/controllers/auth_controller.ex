defmodule Web.AuthController do
  use Web, :controller

  plug Ueberauth

  alias Web.User

  def request(conn, _params) do
    conn
    |> put_flash(:error, "There was an error authenticating.")
    |> redirect(to: public_page_path(conn, :index))
  end

  def callback(conn = %{assigns: %{ueberauth_failure: _fails}}, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: public_page_path(conn, :index))
  end

  def callback(conn = %{assigns: %{ueberauth_auth: auth}}, _params) do
    case User.from_grapevine(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:user_token, user.token)
        |> redirect(to: public_page_path(conn, :index))

      {:ok, :finalize_registration, user} ->
        conn
        |> put_flash(:info, "Please finish registration.")
        |> put_session(:user_token, user.token)
        |> redirect(to: public_registration_path(conn, :finalize))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem signing in. Please contact an administrator.")
        |> redirect(to: public_page_path(conn, :index))
    end
  end
end
