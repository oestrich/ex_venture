defmodule Web.AccountTwoFactorController do
  use Web, :controller

  alias Web.User

  @failed_attempts_limit 3

  plug(Web.Plug.PublicEnsureUser)
  plug(:signout_after_failed_attempts when action in [:verify, :verify_token])

  def start(conn, _params) do
    %{user: user} = conn.assigns
    user = User.create_totp_secret(user)
    conn |> render("start.html", user: user)
  end

  def validate(conn, %{"user" => %{"token" => token}}) do
    %{user: user} = conn.assigns

    case User.valid_totp_token?(user, token) do
      true ->
        User.totp_token_verified(user)

        conn
        |> put_flash(:info, "Your account has Two Factor security enabled!")
        |> redirect(to: public_account_path(conn, :show))

      false ->
        conn
        |> put_flash(:error, "Token was invalid. Try again.")
        |> redirect(to: public_account_two_factor_path(conn, :start))
    end
  end

  def verify(conn, _params) do
    conn |> render("verify.html")
  end

  def verify_token(conn, %{"user" => %{"token" => token}}) do
    %{user: user} = conn.assigns

    case User.valid_totp_token?(user, token) do
      true ->
        conn
        |> put_session(:is_user_totp_verified, true)
        |> redirect(to: public_page_path(conn, :index))

      false ->
        failed_count = get_session(conn, :totp_failed_count) || 0

        conn
        |> put_flash(:error, "Token was invalid. Try again.")
        |> put_session(:totp_failed_count, failed_count + 1)
        |> redirect(to: public_account_two_factor_path(conn, :verify))
    end
  end

  def qr(conn, _params) do
    %{user: user} = conn.assigns

    png = User.generate_qr_png(user)

    conn
    |> put_resp_header("content-type", "image/png")
    |> put_resp_header("cache-control", "private")
    |> send_resp(200, png)
  end

  def signout_after_failed_attempts(conn, _opts) do
    case get_session(conn, :totp_failed_count) do
      @failed_attempts_limit ->
        conn
        |> clear_session()
        |> put_flash(:error, "You reached max token attempts")
        |> redirect(to: public_page_path(conn, :index))
        |> halt()

      _ ->
        conn
    end
  end
end
