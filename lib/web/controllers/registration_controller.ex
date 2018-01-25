defmodule Web.RegistrationController do
  use Web, :controller

  alias Web.User

  def new(conn, _params) do
    changeset = User.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"user" => params}) do
    case User.create(params) do
      {:ok, user} ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: public_play_path(conn, :show))

      {:error, changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end
end
