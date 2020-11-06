defmodule ExVenture.ZonesTest do
  use ExVenture.DataCase

  alias ExVenture.Zones

  describe "creating zones" do
    test "successfully" do
      {:ok, zone} =
        Zones.create(%{
          name: "Zone",
          description: "Description"
        })

      assert zone.name == "Zone"
      assert zone.description == "Description"
    end

    test "unsuccessful" do
      {:error, changeset} =
        Zones.create(%{
          name: nil,
          description: "Description"
        })

      assert changeset.errors[:name]
    end
  end

  describe "updating zones - not live" do
    test "successfully" do
      {:ok, zone} = TestHelpers.create_zone(%{name: "Zone"})

      {:ok, zone} =
        Zones.update(zone, %{
          name: "New Zone"
        })

      assert zone.name == "New Zone"
    end

    test "unsuccessful" do
      {:ok, zone} = TestHelpers.create_zone(%{name: "Zone"})

      {:error, changeset} =
        Zones.update(zone, %{
          name: nil
        })

      assert changeset.errors[:name]
    end
  end

  describe "updating zones - live" do
    test "successfully" do
      {:ok, zone} = TestHelpers.create_zone(%{name: "Zone"})
      {:ok, zone} = TestHelpers.publish_zone(zone)

      {:ok, zone} =
        Zones.update(zone, %{
          name: "New Zone"
        })

      assert zone.name == "Zone"
      assert Enum.count(zone.staged_changes)
    end

    test "unsuccessful" do
      {:ok, zone} = TestHelpers.create_zone(%{name: "Zone"})
      {:ok, zone} = TestHelpers.publish_zone(zone)

      {:error, changeset} =
        Zones.update(zone, %{
          name: nil
        })

      assert changeset.errors[:name]
    end
  end
end
