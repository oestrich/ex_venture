defmodule Game.Command.ExamineTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Short Sword", keywords: [], description: "A simple blade", stats: %{}, effects: []})
    insert_item(%{id: 2, name: "Leather Armor", keywords: [], description: "A simple leather chest piece", stats: %{}, effects: []})

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "looking at an item in inventory", %{session: session, socket: socket} do
    :ok = Command.Examine.run({"short sword"}, session, %{socket: socket, save: %{wearing: %{}, wielding: %{}, items: [item_instance(1)]}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(A simple blade), look)
  end

  test "looking at an item in wearing", %{session: session, socket: socket} do
    :ok = Command.Examine.run({"leather armor"}, session, %{socket: socket, save: %{wearing: %{chest: item_instance(2)}, wielding: %{}, items: []}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(simple leather), look)
  end

  test "looking at an item in wielding", %{session: session, socket: socket} do
    :ok = Command.Examine.run({"short sword"}, session, %{socket: socket, save: %{wearing: %{}, wielding: %{right: item_instance(1)}, items: []}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(A simple blade), look)
  end
end
