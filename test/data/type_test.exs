defmodule Data.TypeTest do
  use ExUnit.Case
  doctest Data.Type

  alias Data.Type
  alias Data.Type.Changeset

  describe "validating keys of a map" do
    setup do
      changeset = %Changeset{data: %{type: "emote"}, valid?: true}
      %{changeset: changeset}
    end

    test "required keys", %{changeset: changeset} do
      expected_changeset = Type.validate_keys(changeset, required: [:type])
      assert expected_changeset.valid?

      expected_changeset = Type.validate_keys(changeset, required: [:message], optional: [:type])
      refute expected_changeset.valid?
      assert expected_changeset.errors[:keys] == ["missing keys: message"]

      expected_changeset = Type.validate_keys(changeset, required: [:type, :message])
      refute expected_changeset.valid?
      assert expected_changeset.errors[:keys] == ["missing keys: message"]
    end

    test "one of a set of required keys" do
      changeset = %Changeset{data: %{action: %{}}, valid?: true}
      expected_changeset = Type.validate_keys(changeset, required: [], one_of: [:action, :actions])
      assert expected_changeset.valid?

      changeset = %Changeset{data: %{actions: []}, valid?: true}
      expected_changeset = Type.validate_keys(changeset, required: [], one_of: [:action, :actions])
      assert expected_changeset.valid?

      changeset = %Changeset{data: %{action: %{}, actions: []}, valid?: true}
      expected_changeset = Type.validate_keys(changeset, required: [], one_of: [:action, :actions])
      refute expected_changeset.valid?

      changeset = %Changeset{data: %{}, valid?: true}
      expected_changeset = Type.validate_keys(changeset, required: [], one_of: [:action, :actions])
      refute expected_changeset.valid?
    end

    test "optional keys", %{changeset: changeset} do
      expected_changeset = Type.validate_keys(changeset, required: [], optional: [:type])
      assert expected_changeset.valid?

      expected_changeset = Type.validate_keys(changeset, required: [:type], optional: [:message])
      assert expected_changeset.valid?
    end

    test "continues to validate if already invalid", %{changeset: changeset} do
      changeset = %{changeset | valid?: false}

      expected_changeset = Type.validate_keys(changeset, required: [:message], optional: [:type])

      refute expected_changeset.valid?
      assert expected_changeset.errors[:keys] == ["missing keys: message"]
    end
  end

  describe "validating values of a map" do
    setup do
      changeset = %Changeset{data: %{type: "emote"}, valid?: true}
      %{changeset: changeset}
    end

    test "calls the function", %{changeset: changeset} do
      expected_changeset = Type.validate_values(changeset, fn _ -> true end)
      assert expected_changeset.valid?

      expected_changeset = Type.validate_values(changeset, fn _ -> false end)
      refute expected_changeset.valid?
      assert expected_changeset.errors[:values] == ["invalid types for: type"]
    end

    test "does nothing if already failing", %{changeset: changeset} do
      changeset = %{changeset | valid?: false}
      expected_changeset = Type.validate_values(changeset, fn _ -> true end)
      refute expected_changeset.valid?
    end
  end

  describe "adding errors" do
    setup do
      changeset = %Changeset{data: %{type: "emote"}, valid?: true}
      %{changeset: changeset}
    end

    test "sets to invalid", %{changeset: changeset} do
      changeset = Changeset.add_error(changeset, :keys, "missing keys")
      assert changeset.errors[:keys] == ["missing keys"]
      refute changeset.valid?
    end
  end
end
