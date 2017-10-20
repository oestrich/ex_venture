defmodule Web.ItemTaggingTest do
  use Data.ModelCase

  alias Web.ItemTagging

  setup do
    item = create_item()
    item_tag = create_item_tag()
    %{item: item, item_tag: item_tag}
  end

  test "create a new item tagging", %{item: item, item_tag: item_tag} do
    {:ok, item_tagging} = ItemTagging.create(item, item_tag.id)

    assert item_tagging.item_tag_id == item_tag.id
  end

  test "delete an item tagging", %{item: item, item_tag: item_tag} do
    {:ok, item_tagging} = ItemTagging.create(item, item_tag.id)
    assert {:ok, _item_tagging} = ItemTagging.delete(item_tagging)
  end
end
