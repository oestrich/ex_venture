defmodule Game.Command.UseTest do
  use Data.ModelCase

  alias Data.Item
  alias Game.Command
  alias Game.Session.Registry

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{
      id: 1,
      name: "Potion",
      keywords: [],
      stats: %{},
      effects: [],
      user_text: "Used a potion",
      usee_text: "",
      is_usable: true,
      amount: 1,
    })
    insert_item(%{
      id: 2,
      name: "Leather Armor",
      keywords: [],
      stats: %{},
      effects: [],
      is_usable: false,
    })

    @socket.clear_messages

    save =
      base_save()
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: 1}])

    %{socket: :socket, session: :session, user: %{id: 1, name: "Player"}, save: save}
  end

  test "use an item - removes if amount ends up as 0", state = %{socket: socket} do
    Registry.register(state.user)

    {:skip, :prompt, state} = Command.Use.run({"potion"}, state.session, state)

    assert [] = state.save.items

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Used a potion), look)
    assert_receive {:"$gen_cast", {:apply_effects, [], {:user, %{id: 1}}, _}}
  end

  test "use an item with an amount - decrements amount", state do
    Registry.register(state.user)

    save =
      base_save()
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: 2}])

    {:skip, :prompt, state} = Command.Use.run({"potion"}, state.session, %{state | save: save})

    assert [%Item.Instance{amount: 1}] = state.save.items
  end

  test "use an item with an amount - -1 is unlimited", state do
    Registry.register(state.user)

    save =
      base_save()
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: -1}])

    assert {:skip, :prompt} = Command.Use.run({"potion"}, state.session, %{state | save: save})
  end

  test "trying to use a non-usable item", state = %{socket: socket} do
    save =
      base_save()
      |> Map.put(:items, [item_instance(2)])

    :ok = Command.Use.run({"leather armor"}, state.session, %{state | save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be used), look)
  end

  test "item not found", state = %{socket: socket} do
    :ok = Command.Use.run({"poton"}, state.session, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be found), look)
  end
end
