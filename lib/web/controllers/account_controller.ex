defmodule Web.AccountController do
  use Web, :controller

  alias Web.User

  plug(Web.Plug.PublicEnsureUser)

  def show(conn, _params) do
    %{user: user} = conn.assigns

    email_changeset = User.email_changeset(user)

    conn
    |> assign(:email_changeset, email_changeset)
    |> render("show.html")
  end

  def password(conn, _params) do
    %{user: user} = conn.assigns

    case User.create_one_time_password(user) do
      {:ok, password} ->
        conn |> render("password.html", password: password)

      {:error, _} ->
        conn |> redirect(to: public_page_path(conn, :index))
    end
  end

  def update(conn, %{"current_password" => current_password, "user" => params}) do
    case User.change_password(conn.assigns.user, current_password, params) do
      {:ok, _user} ->
        conn |> redirect(to: public_page_path(conn, :index))

      _ ->
        conn |> redirect(to: public_account_path(conn, :show))
    end
  end

  def update(conn, %{"user" => params}) do
    %{user: user} = conn.assigns

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
