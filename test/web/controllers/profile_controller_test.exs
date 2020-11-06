defmodule Web.ProfileControllerTest do
  use Web.ConnCase

  describe "updating your profile" do
    test "successful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      params = %{
        email: "user@example.com"
      }

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.profile_path(conn, :update), user: params)

      assert redirected_to(conn) == Routes.profile_path(conn, :show)
    end

    test "failure", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      params = %{email: nil}

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.profile_path(conn, :update), user: params)

      assert html_response(conn, 422)
    end
  end
end
