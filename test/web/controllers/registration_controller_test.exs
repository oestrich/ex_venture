defmodule Web.RegistrationControllerTest do
  use Web.ConnCase

  describe "registering a new user" do
    test "successful", %{conn: conn} do
      params = %{
        email: "user@example.com",
        first_name: "John",
        last_name: "Smith",
        password: "password",
        password_confirmation: "password"
      }

      conn = post(conn, Routes.registration_path(conn, :create), user: params)

      assert redirected_to(conn) == Routes.page_path(conn, :index)
    end

    test "failure", %{conn: conn} do
      params = %{
        email: "user@example.com",
        first_name: "John",
        last_name: "Smith",
        password: "password",
        password_confirmation: "passw0rd"
      }

      conn = post(conn, Routes.registration_path(conn, :create), user: params)

      assert html_response(conn, 422)
    end
  end
end
