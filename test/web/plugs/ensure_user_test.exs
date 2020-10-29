defmodule Web.Plugs.EnsureUserTest do
  use Web.ConnCase

  alias Web.Plugs.EnsureUser

  describe "verifies the user is signed in" do
    test "user is present", %{conn: conn} do
      user = TestHelpers.create_user()

      conn =
        conn
        |> assign(:current_user, user)
        |> bypass_through()
        |> get("/profile")
        |> EnsureUser.call([])

      refute conn.halted
    end

    test "user is not present", %{conn: conn} do
      conn =
        conn
        |> bypass_through(Web.Router, [:browser])
        |> get("/profile")
        |> EnsureUser.call([])

      assert conn.halted
    end
  end
end
