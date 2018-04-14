defmodule Data.TypeTest do
  use ExUnit.Case
  doctest Data.Type

  alias Data.Type

  describe "validating keys of a map" do
    setup do
      changeset = %{data: %{type: "emote"}, valid?: true}

      %{changeset: changeset}
    end

    test "required keys", %{changeset: changeset} do
      changeset = Type.validate_keys(changeset, required: [:type])
      assert changeset.valid?

      changeset = Type.validate_keys(changeset, required: [:message])
      refute changeset.valid?

      changeset = Type.validate_keys(changeset, required: [:type, :message])
      refute changeset.valid?
    end

    test "optional keys", %{changeset: changeset} do
      changeset = Type.validate_keys(changeset, required: [], optional: [:type])
      assert changeset.valid?

      changeset = Type.validate_keys(changeset, required: [:type], optional: [:message])
      assert changeset.valid?
    end

    test "does nothing if already failing", %{changeset: changeset} do
      changeset = %{changeset | valid?: false}
      changeset = Type.validate_keys(changeset, required: [])
      refute changeset.valid?
    end
  end

  describe "validating values of a map" do
    setup do
      changeset = %{data: %{type: "emote"}, valid?: true}

      %{changeset: changeset}
    end

    test "calls the function", %{changeset: changeset} do
      changeset = Type.validate_values(changeset, fn _ -> true end)
      assert changeset.valid?

      changeset = Type.validate_values(changeset, fn _ -> false end)
      refute changeset.valid?
    end

    test "does nothing if already failing", %{changeset: changeset} do
      changeset = %{changeset | valid?: false}
      changeset = Type.validate_values(changeset, fn _ -> true end)
      refute changeset.valid?
    end
  end
end
