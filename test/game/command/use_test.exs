defmodule Game.Command.UseTest do
  use Data.ModelCase

  alias Game.Command
  alias Game.Session.Registry

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Potion", keywords: [], stats: %{}, effects: []})
    insert_item(%{id: 2, name: "Leather Armor", keywords: [], stats: %{}, effects: []})

    @socket.clear_messages

    save = 
      base_save()
      |> Map.put(:items, [item_instance(1)])

    %{socket: :socket, session: :session, user: %{id: 1}, save: save}
  end

  test "use an item", state do
    Registry.register(state.user)

    :ok = Command.Use.run({"potion"}, state.session, state)

    assert_receive {:"$gen_cast", {:apply_effects, [], {:user, %{id: 1}}, _}}
  end

  test "item not found", state = %{socket: socket} do
    :ok = Command.Use.run({"poton"}, state.session, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be found), look)
  end
end
