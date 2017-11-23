defmodule Data.SaveTest do
  use ExUnit.Case
  import TestHelpers
  doctest Data.Save

  alias Data.Save

  test "ensures channels is always an array when loading" do
    {:ok, save} = Save.load(%{})
    assert save.channels == []
  end

  describe "migrate old save data" do
    test "migrate item_ids to item instances" do
      save = %{item_ids: [1], version: 1}
      save = Save.migrate(save)

      assert save.version == 2
      assert [%{id: 1}] = save.items
    end

    test "will migrate as far as it can" do
      save = %{item_ids: [1]}
      save = Save.migrate(save)

      assert save.version == 2
      assert [%{id: 1}] = save.items
    end
  end
end
