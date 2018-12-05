defmodule Game.NPC.Actions.CommandsSkillTest do
  use Data.ModelCase

  alias Data.Events.Actions
  alias Game.Character
  alias Game.NPC.Actions.CommandsSkill
  alias Game.NPC.State
  alias Game.Session.Registry

  doctest CommandsSkill

  @room Test.Game.Room

  setup [:basic_setup]

  describe "using skills" do
    test "uses the skill", %{state: state, action: action, player: player} do
      state = %{state | combat: true, target: {:player, player}}

      {:ok, ^state} = CommandsSkill.act(state, action)

      assert_receive {:"$gen_cast", {:apply_effects, _, _, _}}
    end

    test "no skill found", %{state: state, action: action, player: player} do
      state = %{state | combat: true, target: {:player, player}}
      action = %{action | options: %{skill: "bash"}}

      {:ok, ^state} = CommandsSkill.act(state, action)

      refute_receive {:"$gen_cast", {:apply_effects, _, _, _}}, 50
    end

    test "with no target", %{state: state, action: action} do
      state = %{state | combat: true, target: nil}

      {:ok, state} = CommandsSkill.act(state, action)

      refute state.combat
      refute_receive {:"$gen_cast", {:apply_effects, _, _, _}}, 50
    end

    test "with target not in the room", %{state: state, action: action, player: player} do
      @room._room()
      |> Map.put(:players, [])
      |> @room.set_room()

      state = %{state | combat: true, target: {:player, player}}

      {:ok, state} = CommandsSkill.act(state, action)

      refute state.combat
      refute_receive {:"$gen_cast", {:apply_effects, _, _, _}}, 50
    end
  end

  def basic_setup(_) do
    npc = npc_attributes(%{id: 1})

    state = %State{
      room_id: 1,
      npc: npc,
    }

    player = %Character.Simple{
      id: 1,
      type: :player,
      name: "Player",
    }

    notify_user = %{base_user() | id: player.id}
    notify_character = %{base_character(notify_user) | id: player.id}
    Registry.register(notify_character)
    Registry.catch_up()

    @room._room()
    |> Map.put(:players, [player])
    |> @room.set_room()

    start_and_clear_skills()
    insert_skill(create_skill(%{command: "slash"}))

    action = %Actions.CommandsSkill{
      options: %{skill: "slash"}
    }

    %{state: state, action: action, player: player}
  end
end
