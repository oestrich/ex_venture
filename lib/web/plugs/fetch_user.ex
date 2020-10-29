defmodule Web.Plugs.FetchUser do
  @moduledoc """
  Fetch a user from the session
  """

  import Plug.Conn

  alias ExVenture.Users

  def init(default), do: default

  def call(conn, _opts) do
    case conn |> get_session(:user_token) do
      nil ->
        conn

      token ->
        load_user(conn, Users.from_token(token))
    end
  end

  defp load_user(conn, {:ok, user}) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

  defp load_user(conn, _), do: conn
end
