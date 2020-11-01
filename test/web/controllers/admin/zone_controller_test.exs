defmodule Web.Admin.ZoneControllerTest do
  use Web.ConnCase

  describe "creating a zone" do
    test "successful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_admin()

      conn =
        conn
        |> assign(:current_user, user)
        |> post(Routes.admin_zone_path(conn, :create),
          zone: %{
            name: "Name",
            description: "Description"
          }
        )

      assert redirected_to(conn) =~ ~r/\/admin\/zones\/\d+/
    end

    test "unsuccessful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_admin()

      conn =
        conn
        |> assign(:current_user, user)
        |> post(Routes.admin_zone_path(conn, :create),
          zone: %{
            name: "Name"
          }
        )

      assert html_response(conn, 422)
    end
  end

  describe "updating a zone" do
    test "successful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_admin()

      {:ok, zone} = TestHelpers.create_zone()

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.admin_zone_path(conn, :update, zone.id),
          zone: %{
            name: "Name",
            description: "Description"
          }
        )

      assert redirected_to(conn) == Routes.admin_zone_path(conn, :show, zone.id)
    end

    test "unsuccessful", %{conn: conn} do
      {:ok, user} = TestHelpers.create_admin()

      {:ok, zone} = TestHelpers.create_zone()

      conn =
        conn
        |> assign(:current_user, user)
        |> put(Routes.admin_zone_path(conn, :update, zone.id),
          zone: %{
            name: "Name",
            description: nil
          }
        )

      assert html_response(conn, 422)
    end
  end
end
