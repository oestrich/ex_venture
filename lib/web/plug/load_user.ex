defmodule Web.Plug.LoadUser do
  @moduledoc """
  Plug for loading the user and generating a secure token for playing
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    case conn |> get_session(:user_token) do
      nil -> conn
      token -> conn |> _load_user(Web.User.from_token(token))
    end
  end

  defp _load_user(conn, nil), do: conn

  defp _load_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:user, user)
    |> assign(:user_token, token)
  end
end
