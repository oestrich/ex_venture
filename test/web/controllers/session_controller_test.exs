defmodule Web.SessionControllerTest do
  use Web.ConnCase

  describe "signing in" do
    test "valid", %{conn: conn} do
      {:ok, user} =
        TestHelpers.create_user(%{
          email: "user@example.com",
          password: "password"
        })

      conn =
        post(conn, Routes.session_path(conn, :create),
          user: [email: user.email, password: "password"]
        )

      assert redirected_to(conn) == Routes.page_path(conn, :index)
    end

    test "invalid", %{conn: conn} do
      {:ok, user} =
        TestHelpers.create_user(%{
          email: "user@example.com",
          password: "password"
        })

      conn =
        post(conn, Routes.session_path(conn, :create),
          user: [email: user.email, password: "invalid"]
        )

      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end
  end
end
