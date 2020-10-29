defmodule Web.ConfirmationController do
  use Web, :controller

  alias ExVenture.Users

  action_fallback(Web.FallbackController)

  def confirm(conn, %{"code" => code}) do
    case Users.verify_email(code) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Thanks for verifying your email!")
        |> put_session(:user_token, user.token)
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "There was an issue verifying your account")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def confirm(conn, _params) do
    conn
    |> put_flash(:error, "There was an issue verifying your account")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
