defmodule Web.AccountController do
  use Web, :controller

  alias Web.User

  plug(:ensure_user!)

  def show(conn, _params) do
    conn |> render("show.html")
  end

  def update(conn, %{"user" => params}) do
    case User.change_password(conn.assigns.user, params["current_password"], params) do
      {:ok, _user} ->
        conn |> redirect(to: public_page_path(conn, :index))

      _ ->
        conn |> redirect(to: public_account_path(conn, :show))
    end
  end

  defp ensure_user!(conn, _opts) do
    case Map.has_key?(conn.assigns, :user) do
      true -> conn
      false -> conn |> redirect(to: session_path(conn, :new)) |> halt()
    end
  end
end
