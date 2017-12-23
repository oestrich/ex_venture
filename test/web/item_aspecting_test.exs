defmodule Web.ItemAspectingTest do
  use Data.ModelCase

  alias Web.ItemAspecting

  setup do
    item = create_item()
    item_aspect = create_item_aspect()
    %{item: item, item_aspect: item_aspect}
  end

  test "create a new item aspecting", %{item: item, item_aspect: item_aspect} do
    {:ok, item_aspecting} = ItemAspecting.create(item, %{item_aspect_id: item_aspect.id})

    assert item_aspecting.item_aspect_id == item_aspect.id
  end

  test "delete an item aspecting", %{item: item, item_aspect: item_aspect} do
    {:ok, item_aspecting} = ItemAspecting.create(item, %{item_aspect_id: item_aspect.id})
    assert {:ok, _item_aspecting} = ItemAspecting.delete(item_aspecting)
  end
end
