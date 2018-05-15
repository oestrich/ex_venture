defmodule Web.RegistrationController do
  use Web, :controller

  alias Game.Config
  alias Web.User

  def new(conn, _params) do
    changeset = User.new()

    conn
    |> assign(:changeset, changeset)
    |> assign(:names, Config.random_character_names())
    |> render("new.html")
  end

  def create(conn, %{"user" => params}) do
    case User.create(params) do
      {:ok, user} ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: public_play_path(conn, :show))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end
end
