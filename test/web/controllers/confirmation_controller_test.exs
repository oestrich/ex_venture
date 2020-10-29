defmodule Web.ConfirmationControllerTest do
  use Web.ConnCase

  describe "confirming an email" do
    test "valid token", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      conn =
        get(conn, Routes.confirmation_path(conn, :confirm), code: user.email_verification_token)

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :user_token)
    end

    test "invalid token", %{conn: conn} do
      conn = get(conn, Routes.confirmation_path(conn, :confirm), code: "a token")

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      refute get_session(conn, :user_token)
    end

    test "missing a token", %{conn: conn} do
      conn = get(conn, Routes.confirmation_path(conn, :confirm))

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      refute get_session(conn, :user_token)
    end
  end
end
