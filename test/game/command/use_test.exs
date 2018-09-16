defmodule Game.Command.UseTest do
  use Data.ModelCase
  doctest Game.Command.Use

  alias Data.Item
  alias Game.Command.ParseContext
  alias Game.Command.Use
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
      usage_command: "drink",
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

    user = %{base_user() | id: 1, save: save}

    %{socket: :socket, user: user, save: user.save}
  end

  describe "parsing a custom command" do
    test "pick up an item's custom command", state do
      context = %ParseContext{player: state.user}
      assert {:use, "potion"} = Use.parse("drink potion", context)
    end
  end

  test "use an item - removes if amount ends up as 0", state = %{socket: socket} do
    Registry.register(state.user)
    Registry.catch_up()

    {:skip, :prompt, state} = Use.run({:use, "potion"}, state)

    assert [] = state.save.items

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Used a potion), look)
    assert_receive {:"$gen_cast", {:apply_effects, [], {:player, %{id: 1}}, _}}
  end

  test "use an item with an amount - decrements amount", state do
    Registry.register(state.user)
    Registry.catch_up()

    save =
      base_save()
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: 2}])

    {:skip, :prompt, state} = Use.run({:use, "potion"}, %{state | save: save})

    assert [%Item.Instance{amount: 1}] = state.save.items
  end

  test "use an item with an amount - -1 is unlimited", state do
    Registry.register(state.user)
    Registry.catch_up()

    save =
      base_save()
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: -1}])

    assert {:skip, :prompt} = Use.run({:use, "potion"}, %{state | save: save})
  end

  test "trying to use a non-usable item", state = %{socket: socket} do
    save =
      base_save()
      |> Map.put(:items, [item_instance(2)])

    :ok = Use.run({:use, "leather armor"}, %{state | save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be used), look)
  end

  test "item not found", state = %{socket: socket} do
    :ok = Use.run({:use, "poton"}, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be found), look)
  end
end
