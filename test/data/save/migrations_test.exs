defmodule Data.Save.MigrationsTest do
  use ExUnit.Case

  alias Data.Save.Config
  alias Data.Save.Migrations

  describe "migrate old save data" do
    test "migrate item_ids to item instances" do
      save = %{item_ids: [1], version: 1}
      save = Migrations.migrate(save)

      assert save.version > 1
      assert [%{id: 1}] = save.items
    end

    test "migrates wearing and wielding items" do
      save = %{wielding: %{right: 1}, wearing: %{chest: 1}}
      save = Migrations.migrate(save)

      assert save.version > 2
      assert %{right: %{id: 1}} = save.wielding
      assert %{chest: %{id: 1}} = save.wearing
    end

    test "will migrate as far as it can" do
      save = %{item_ids: [1]}
      save = Migrations.migrate(save)

      assert save.version > 0
      assert [%{id: 1}] = save.items
    end
  end

  describe "migrating config" do
    test "adds prompt" do
      save = %{config: %{}}

      save = Migrations.migrate_config(save)

      assert save.config.prompt == Config.default_prompt()
    end
  end
end
