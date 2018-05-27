defmodule Web.ConnectionController do
  use Web, :controller

  alias Web.User

  plug(Web.Plug.PublicEnsureUser)

  def authorize(conn, %{"id" => id}) do
    conn
    |> assign(:telnet_id, id)
    |> render("authorize.html")
  end

  def connect(conn, %{"id" => id}) do
    %{user: user} = conn.assigns

    User.authorize_connection(user, id)

    conn
    |> put_flash(:info, "Connection authorized, you are signed in!")
    |> redirect(to: public_page_path(conn, :index))
  end
end
