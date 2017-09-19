defmodule Web.AccountControllerTest do
  use Web.AuthConnCase

  test "change your password", %{conn: conn} do
    conn = put conn, public_account_path(conn, :update), user: %{current_password: "password", password: "p@ssw0rd", password_confirmation: "p@ssw0rd"}
    assert redirected_to(conn) == public_page_path(conn, :index)
  end

  test "bad current password", %{conn: conn} do
    conn = put conn, public_account_path(conn, :update), user: %{current_password: "lassword", password: "p@ssw0rd", password_confirmation: "p@ssw0rd"}
    assert redirected_to(conn) == public_account_path(conn, :show)
  end
end
