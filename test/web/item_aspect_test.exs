defmodule Web.ItemAspectTest do
  use Data.ModelCase

  alias Web.ItemAspect

  test "create a new item module" do
    params = %{
      "name" => "Helmet",
      "description" => "A helmet",
      "type" => "armor",
      "stats" => ~s({"slot":"head","armor":10}),
      "effects" => ~s([{"kind":"stats","field":"strength","amount":10}]),
    }

    {:ok, item_module} = ItemAspect.create(params)

    assert item_module.name == "Helmet"
  end

  test "update an item module" do
    params = %{
      "name" => "Helmet",
      "description" => "A helmet",
      "type" => "armor",
      "stats" => ~s({"slot":"head","armor":10}),
      "effects" => ~s([{"kind":"stats","field":"strength","amount":10}]),
    }

    {:ok, item_module} = ItemAspect.create(params)
    {:ok, item_module} = ItemAspect.update(item_module.id, %{"name" => "Full Plate Helmet"})

    assert item_module.name == "Full Plate Helmet"
  end
end
