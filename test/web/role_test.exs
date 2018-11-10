defmodule Web.RoleTest do
  use Data.ModelCase

  alias Web.Role

  test "creating a role" do
    params = %{
      "name" => "Admins",
    }

    {:ok, role} = Role.create(params)

    assert role.name == "Admins"
  end

  test "updating a role" do
    role = create_role(%{name: "Admins"})

    {:ok, role} = Role.update(role.id, %{name: "Immortals"})

    assert role.name == "Immortals"
  end
end
