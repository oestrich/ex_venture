defmodule ExVenture.StagedChangesTest do
  use ExVenture.DataCase

  alias ExVenture.StagedChanges

  describe "recording changes" do
    test "saves any changes as key/value records" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> Ecto.Changeset.put_change(:description, "New Description")
        |> StagedChanges.record_changes()

      assert Enum.count(zone.staged_changes) == 2

      name_change =
        Enum.find(zone.staged_changes, fn staged_change ->
          staged_change.attribute == :name
        end)

      assert name_change.attribute == :name
      assert name_change.value == "New Name"
    end

    test "stashes an attribute with the current value only" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> StagedChanges.record_changes()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "Newer Name")
        |> StagedChanges.record_changes()

      assert Enum.count(zone.staged_changes) == 1

      name_change =
        Enum.find(zone.staged_changes, fn staged_change ->
          staged_change.attribute == :name
        end)

      assert name_change.attribute == :name
      assert name_change.value == "Newer Name"
    end

    test "able to apply the recorded changes to the struct" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> StagedChanges.record_changes()

      zone = StagedChanges.apply(zone)

      assert zone.name == "New Name"
    end
  end

  describe "commit changes" do
    test "converts staged changes into full structs" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> StagedChanges.record_changes()

      StagedChanges.commit()

      zone = Repo.reload(zone)
      assert zone.name == "New Name"

      assert Repo.all({"zone_staged_changes", StagedChanges.StagedChange}) == []
    end
  end

  describe "getting all structs with changes" do
    test "includes zones" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> StagedChanges.record_changes()

      %{ExVenture.Zones.Zone => zone_changes} = StagedChanges.changes()

      assert Enum.map(zone_changes, & &1.id) == Enum.map(zone.staged_changes, & &1.id)
    end
  end

  describe "clearing changes" do
    test "removes all staged changes" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, zone} =
        zone
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:name, "New Name")
        |> StagedChanges.record_changes()

      StagedChanges.clear(zone)

      assert Repo.all({"zone_staged_changes", StagedChanges.StagedChange}) == []
    end
  end
end
