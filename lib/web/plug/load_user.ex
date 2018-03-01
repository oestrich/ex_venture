defmodule Web.Plug.LoadUser do
  @moduledoc """
  Plug for loading the user and generating a secure token for playing
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Web.Router.Helpers, as: Routes
  alias Web.User

  def init(default), do: default

  def call(conn, opts) do
    case conn |> get_session(:user_token) do
      nil ->
        conn

      token ->
        conn |> _load_user(Web.User.from_token(token), opts)
    end
  end

  defp _load_user(conn, nil, _opts), do: conn

  defp _load_user(conn, user, verify: false) do
    conn |> _assign_user(user)
  end

  defp _load_user(conn, user, _opts) do
    case User.totp_verified?(user) do
      true ->
        conn |> check_totp_verified(user)

      false ->
        conn |> _assign_user(user)
    end
  end

  defp check_totp_verified(conn, user) do
    case conn |> get_session(:is_user_totp_verified) do
      true ->
        _assign_user(conn, user)

      _ ->
        conn
        |> redirect(to: Routes.public_account_two_factor_path(conn, :verify))
        |> halt()
    end
  end

  defp _assign_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:user, user)
    |> assign(:user_token, token)
  end
end
