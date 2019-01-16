defmodule Game.Command.ExamineTest do
  use ExVenture.CommandCase

  alias Game.Command

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Short Sword", keywords: [], description: "A simple blade", stats: %{}, effects: []})
    insert_item(%{id: 2, name: "Leather Armor", keywords: [], description: "A simple leather chest piece", stats: %{}, effects: []})

    {:ok, %{socket: :socket}}
  end

  test "looking at an item in inventory", %{socket: socket} do
    :ok = Command.Examine.run({"short sword"}, %{socket: socket, save: %{wearing: %{}, wielding: %{}, items: [item_instance(1)]}})

    assert_socket_echo "a simple blade"
  end

  test "looking at an item in wearing", %{socket: socket} do
    :ok = Command.Examine.run({"leather armor"}, %{socket: socket, save: %{wearing: %{chest: item_instance(2)}, wielding: %{}, items: []}})

    assert_socket_echo "simple leather"
  end

  test "looking at an item in wielding", %{socket: socket} do
    :ok = Command.Examine.run({"short sword"}, %{socket: socket, save: %{wearing: %{}, wielding: %{right: item_instance(1)}, items: []}})

    assert_socket_echo "a simple blade"
  end
end
