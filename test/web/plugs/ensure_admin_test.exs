defmodule Web.Plugs.EnsureAdminTest do
  use Web.ConnCase

  alias Web.Plugs.EnsureAdmin

  describe "verifies the user is signed in" do
    test "user is an admin", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      conn =
        conn
        |> assign(:current_user, %{user | role: "admin"})
        |> bypass_through()
        |> get("/admin")
        |> EnsureAdmin.call([])

      refute conn.halted
    end

    test "user is not present", %{conn: conn} do
      {:ok, user} = TestHelpers.create_user()

      conn =
        conn
        |> assign(:current_user, %{user | role: "player"})
        |> bypass_through(Web.Router, [:browser])
        |> get("/admin")
        |> EnsureAdmin.call([])

      assert conn.halted
    end
  end
end
