defmodule Data.RoleTest do
  use ExUnit.Case

  alias Data.Role

  doctest Data.Role

  describe "validating permissions" do
    test "with valid permission" do
      changeset = %Role{} |> Role.changeset(%{permissions: ["rooms/read"]})
      refute changeset.errors[:permissions]
    end

    test "with invalid permission" do
      changeset = %Role{} |> Role.changeset(%{permissions: ["unknown/read"]})
      assert changeset.errors[:permissions]
    end
  end
end
