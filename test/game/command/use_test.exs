defmodule Game.Command.UseTest do
  use ExVenture.CommandCase

  alias Data.Item
  alias Game.Command.ParseContext
  alias Game.Command.Use
  alias Game.Session.Registry
  alias Game.Character

  doctest Use

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
    insert_item(%{
      id: 3,
      name: "Potion",
      keywords: [],
      stats: %{},
      effects: [],
      usage_command: "drink",
      user_text: "You used [name] on [target].",
      usee_text: "[user] uses [name] on you.",
      is_usable: true,
      amount: 1,
    })
    user = base_user()
    character = base_character(user)

    save =
      character.save
      |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: 1}])

    character = %{character | save: save}

    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "parsing a custom command" do
    test "pick up an item's custom command", %{state: state} do
      context = %ParseContext{player: state.character}
      assert {:use, "potion"} = Use.parse("drink potion", context)
    end
  end

  describe "using a normal item" do
    test "use an item - removes if amount ends up as 0", %{state: state} do
      Registry.register(state.character)
      Registry.catch_up()

      {:skip, :prompt, state} = Use.run({:use, "potion"}, state)

      assert [] = state.save.items

      assert_socket_echo "used a potion"
      assert_receive {:"$gen_cast", {:apply_effects, [], %{id: 10}, _}}
    end

    test "use an item with an amount - decrements amount", %{state: state} do
      Registry.register(state.character)
      Registry.catch_up()

      save =
        base_save()
        |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: 2}])

      {:skip, :prompt, state} = Use.run({:use, "potion"}, %{state | save: save})

      assert [%Item.Instance{amount: 1}] = state.save.items
    end

    test "use an item with an amount - -1 is unlimited", %{state: state} do
      Registry.register(state.character)
      Registry.catch_up()

      save =
        base_save()
        |> Map.put(:items, [%Item.Instance{id: 1, created_at: Timex.now(), amount: -1}])

      assert {:skip, :prompt} = Use.run({:use, "potion"}, %{state | save: save})
    end

    test "trying to use a non-usable item", %{state: state} do
      save =
        base_save()
        |> Map.put(:items, [item_instance(2)])

      :ok = Use.run({:use, "leather armor"}, %{state | save: save})

      assert_socket_echo "could not be used"
    end

    test "item not found", %{state: state} do
      :ok = Use.run({:use, "poton"}, state)

      assert_socket_echo "could not be found"
    end

     test "use command should have a npc target", %{state: state} do
      Registry.register(state.character)
      Registry.catch_up()

      save =
        base_save()
        |> Map.put(:items, [%Item.Instance{id: 3, created_at: Timex.now(), amount: 2}])


      npc = %{base_npc() | id: 5}
      state = %{state | target: npc}
      {:skip, :prompt, state} = Use.run({:use, "potion"}, %{state | save: save})

      assert_socket_echo "You used {item}Potion{/item} on {npc}Bandit{/npc}."
    end

     test "use command should have the player as the target", %{state: state} do
      Registry.register(state.character)
      Registry.catch_up()

      save =
        base_save()
        |> Map.put(:items, [%Item.Instance{id: 3, created_at: Timex.now(), amount: 2}])

      state = %{state | target: nil}
      {:skip, :prompt, state} = Use.run({:use, "potion"}, %{state | save: save})

      assert_socket_echo "You used {item}Potion{/item} on {player}Player{/player}."
    end
  end
end
