defmodule Web.ProfileControllerTest do
  use Web.ConnCase

  describe "registering a new user" do
    test "successful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      params = %{
        email: "user@example.com",
        first_name: "John",
        last_name: "Smith"
      }

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.profile_path(conn, :update), user: params)

      assert redirected_to(conn) == Routes.profile_path(conn, :show)
    end

    test "failure", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      params = %{first_name: nil}

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.profile_path(conn, :update), user: params)

      assert html_response(conn, 422)
    end
  end
end
