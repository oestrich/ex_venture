defmodule Web.RegistrationResetControllerTest do
  use Web.ConnCase
  use Bamboo.Test

  alias ExVenture.Users

  describe "starting reset" do
    test "sends an email", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      conn = post(conn, Routes.registration_reset_path(conn, :create), user: [email: user.email])

      assert redirected_to(conn) == Routes.session_path(conn, :new)
      assert_email_delivered_with(to: [nil: user.email])
    end
  end

  describe "changing your password" do
    test "valid token", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()
      Users.start_password_reset(user.email)
      {:ok, user} = Users.get(user.id)

      params = [
        token: user.password_reset_token,
        user: [password: "password"]
      ]

      conn = post(conn, Routes.registration_reset_path(conn, :update), params)

      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end
  end
end
