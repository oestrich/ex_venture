defmodule Web.RegistrationController do
  use Web, :controller

  alias Game.Config
  alias Web.User

  plug(Web.Plug.PublicEnsureUser when action in [:finalize, :update])
  plug(:ensure_registration_enabled?)

  def new(conn, _params) do
    changeset = User.new()

    conn
    |> assign(:changeset, changeset)
    |> assign(:names, Config.random_character_names())
    |> render("new.html")
  end

  def create(conn, %{"user" => params}) do
    case User.create(params) do
      {:ok, user, _character} ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: public_play_path(conn, :show))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:names, Config.random_character_names())
        |> render("new.html")
    end
  end

  def finalize(conn, _params) do
    %{current_user: user} = conn.assigns

    with true <- User.finalize_registration?(user) do
      changeset = User.finalize(user)

      conn
      |> assign(:changeset, changeset)
      |> render("finalize.html")
    else
      _ ->
        redirect(conn, to: public_page_path(conn, :index))
    end
  end

  def update(conn, %{"user" => params}) do
    %{current_user: user} = conn.assigns

    with true <- User.finalize_registration?(user),
         {:ok, _user} <- User.finalize_user(user, params) do
      redirect(conn, to: public_page_path(conn, :index))
    else
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("finalize.html")

      _ ->
        redirect(conn, to: public_page_path(conn, :index))
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
