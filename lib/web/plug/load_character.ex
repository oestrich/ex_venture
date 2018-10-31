defmodule Web.Plug.LoadCharacter do
  @moduledoc """
  Plug for loading the user and generating a secure token for playing
  """

  import Plug.Conn

  alias Web.Character

  def init(default), do: default

  def call(conn, _opts) do
    case conn.assigns do
      %{user: user} when user != nil ->
        load_character(conn, user)

      _ ->
        conn
    end
  end

  defp load_character(conn, user) do
    case conn |> get_session(:current_character_id) do
      nil ->
        conn
        |> load_any_character(user)
        |> assign_token()

      character_id ->
        case Character.get_character(user, character_id) do
          {:error, :not_found} ->
            conn
            |> load_any_character(user)
            |> assign_token()

          {:ok, character} ->
            conn
            |> put_session(:current_character_id, character.id)
            |> assign(:current_character, character)
            |> assign_token()
        end
    end
  end

  defp load_any_character(conn, user) do
    character = List.first(user.characters)

    conn
    |> assign(:current_character, character)
    |> put_session(:current_character_id, character.id)
  end

  defp assign_token(conn) do
    token = Phoenix.Token.sign(conn, "character socket", conn.assigns.current_character.id)
    assign(conn, :character_token, token)
  end
end
