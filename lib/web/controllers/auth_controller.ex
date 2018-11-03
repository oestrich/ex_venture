defmodule Web.AuthController do
  use Web, :controller

  plug Ueberauth

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
    IO.inspect auth

    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> redirect(to: "/")
  end
end
