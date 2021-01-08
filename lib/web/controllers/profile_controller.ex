defmodule Web.ProfileController do
  use Web, :controller

  alias ExVenture.Characters
  alias ExVenture.Users

  def show(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:user, user)
    |> assign(:characters, Characters.all_for(user))
    |> render("show.html")
  end

  def edit(conn, _params) do
    %{current_user: user} = conn.assigns

    conn
    |> assign(:user, user)
    |> assign(:changeset, Users.edit(user))
    |> render("edit.html")
  end

  def update(conn, %{"user" => params = %{"current_password" => password}}) do
    %{current_user: user} = conn.assigns

    case Users.change_password(user, password, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated.")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Could not update your password.")
        |> redirect(to: Routes.profile_path(conn, :edit))
    end
  end

  def update(conn, %{"user" => params}) do
    %{current_user: user} = conn.assigns

    case Users.update(user, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Profile updated")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, changeset} ->
        conn
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> put_status(422)
        |> render("edit.html")
    end
  end
end
