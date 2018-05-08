defmodule Web.RegistrationResetController do
  use Web, :controller

  alias Web.User

  def new(conn, _params) do
    changeset = User.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    User.reset_password(email)

    conn
    |> put_flash(:info, "Password reset started!")
    |> redirect(to: public_session_path(conn, :new))
  end
end
