defmodule Web.RegistrationResetController do
  use Web, :controller

  alias Web.User

  plug(:ensure_registration_enabled?)

  def new(conn, _params) do
    changeset = User.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    User.start_password_reset(email)

    conn
    |> put_flash(:info, "Password reset started!")
    |> redirect(to: public_session_path(conn, :new))
  end

  def edit(conn, %{"token" => token}) do
    changeset = User.new()

    conn
    |> assign(:token, token)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"token" => token, "user" => params}) do
    case User.reset_password(token, params) do
      :error ->
        conn
        |> put_flash(:info, "There was an issue resetting.")
        |> redirect(to: public_session_path(conn, :new))

      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password reset!")
        |> redirect(to: public_session_path(conn, :new))
    end
  end

  def ensure_registration_enabled?(conn, _opts) do
    case Config.grapevine_only_login?() do
      true ->
        conn
        |> redirect(to: public_session_path(conn, :new))
        |> halt()

      false ->
        conn
    end
  end
end
