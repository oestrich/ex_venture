defmodule Web.AccountTwoFactorController do
  use Web, :controller

  alias Web.User

  plug(Web.Plug.PublicEnsureUser)

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

  def qr(conn, _params) do
    %{user: user} = conn.assigns

    png = User.generate_qr_png(user)

    conn
    |> put_resp_header("content-type", "image/png")
    |> put_resp_header("cache-control", "private")
    |> send_resp(200, png)
  end
end
