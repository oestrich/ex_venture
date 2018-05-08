defmodule Web.AccountControllerTest do
  use Web.AuthConnCase

  test "change your password", %{conn: conn} do
    params = %{
      current_password: "password",
      password: "p@ssw0rd",
      password_confirmation: "p@ssw0rd"
    }

    conn = put conn, public_account_path(conn, :update), user: params

    assert redirected_to(conn) == public_account_path(conn, :show)
  end

  test "bad current password", %{conn: conn} do
    params = %{
      current_password: "lassword",
      password: "p@ssw0rd",
      password_confirmation: "p@ssw0rd"
    }

    conn = put conn, public_account_path(conn, :update), user: params

    assert redirected_to(conn) == public_account_path(conn, :show)
  end

  test "update email", %{conn: conn} do
    params = %{
      email: "new-email@example.com",
    }

    conn = put conn, public_account_path(conn, :update), user: params

    assert redirected_to(conn) == public_account_path(conn, :show)
  end
end
