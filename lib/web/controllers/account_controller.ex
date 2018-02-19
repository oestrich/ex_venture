defmodule Web.AccountController do
  use Web, :controller

  alias Web.User

  plug(Web.Plug.EnsureUser)

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
end
