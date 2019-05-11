defmodule Web.AccountController do
  use Web, :controller

  alias Web.User

  plug(Web.Plug.PublicEnsureUser)

  def show(conn, _params) do
    %{current_user: user} = conn.assigns

    email_changeset = User.email_changeset(user)

    conn
    |> assign(:email_changeset, email_changeset)
    |> render("show.html")
  end

  def update(conn, %{"user" => params = %{"current_password" => current_password}}) do
    case User.change_password(conn.assigns.current_user, current_password, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated")
        |> redirect(to: public_account_path(conn, :show))

      _ ->
        conn
        |> put_flash(:error, "Could not update your password")
        |> redirect(to: public_account_path(conn, :show))
    end
  end

  def update(conn, %{"user" => params}) do
    %{current_user: user} = conn.assigns

    case User.change_email(user, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email updated!")
        |> redirect(to: public_account_path(conn, :show))

      _ ->
        conn
        |> put_flash(:info, "There was an issue updating your email. Please try again.")
        |> redirect(to: public_account_path(conn, :show))
    end
  end
end
