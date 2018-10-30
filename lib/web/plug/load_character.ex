defmodule Web.Plug.LoadCharacter do
  @moduledoc """
  Plug for loading the user and generating a secure token for playing
  """

  import Plug.Conn

  alias Web.User

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
        load_any_character(conn, user)

      character_id ->
        case User.get_character(user, character_id) do
          {:error, :not_found} ->
            load_any_character(conn, user)

          {:ok, character} ->
            conn
            |> put_session(:current_character_id, character.id)
            |> assign(:current_character, character)
        end
    end
  end

  defp load_any_character(conn, user) do
    character = List.first(user.characters)

    conn
    |> assign(:current_character, character)
    |> put_session(:current_character_id, character.id)
  end
end
