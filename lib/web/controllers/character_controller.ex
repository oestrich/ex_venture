defmodule Web.CharacterController do
  use Web, :controller

  alias Game.Config
  alias Web.Character

  plug(Web.Plug.PublicEnsureUser)

  def new(conn, _params) do
    conn
    |> assign(:changeset, Character.new())
    |> assign(:names, Config.random_character_names())
    |> render("new.html")
  end

  def create(conn, %{"character" => params}) do
    %{current_user: user} = conn.assigns

    case Character.create(user, params) do
      {:ok, character} ->
        conn
        |> put_session(:current_character_id, character.id)
        |> redirect(to: public_play_path(conn, :show))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:names, Config.random_character_names())
        |> render("new.html")
    end
  end

  def swap(conn, %{"to" => id}) do
    %{current_user: user} = conn.assigns

    case Character.get_character(user, id) do
      {:ok, character} ->
        conn
        |> put_session(:current_character_id, character.id)
        |> redirect_back()

      {:error, :not_found} ->
        redirect_back(conn)
    end
  end

  defp redirect_back(conn) do
    case get_req_header(conn, "referer") do
      [uri] ->
        uri = URI.parse(uri)
        redirect(conn, to: uri.path)

      _ ->
        redirect(conn, to: public_page_path(conn, :index))
    end
  end
end
