defmodule Web.Plugs.ValidateAPIKeyTest do
  use Web.ConnCase

  alias Web.Plugs.ValidateAPIKey

  describe "validate the bearer token" do
    test "success: valid and active", %{conn: conn} do
      {:ok, api_key} = TestHelpers.create_api_key()

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> api_key.token)
        |> ValidateAPIKey.call([])

      refute conn.halted
    end

    test "failure: valid but inactive key", %{conn: conn} do
      {:ok, api_key} = TestHelpers.create_api_key(%{is_active: false})

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> api_key.token)
        |> ValidateAPIKey.call([])

      assert conn.halted
    end

    test "failure: invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> Ecto.UUID.generate())
        |> ValidateAPIKey.call([])

      assert conn.halted
    end

    test "failure: missing the authorization header", %{conn: conn} do
      conn = ValidateAPIKey.call(conn, [])

      assert conn.halted
    end
  end
end
