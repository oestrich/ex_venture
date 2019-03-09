defmodule Game.NPC.ActionsTest do
  use Data.ModelCase

  alias Data.Events.Actions.CommandsEmote
  alias Data.Events.Actions.CommandsSay
  alias Data.Events.Actions.CommandsSkill
  alias Game.NPC.Actions
  alias Game.NPC.State

  doctest Actions

  describe "delaying a batch of actions" do
    test "pulls of the first even for delaying" do
      action = %CommandsSkill{
        delay: 0.01
      }

      Actions.delay([action])

      assert_receive {:delayed_actions, [action]}
    end

    test "no more actions" do
      Actions.delay([])

      refute_received {:delayed_actions, []}
    end
  end

  describe "process actions" do
    test "runs the first action and processes the rest" do
      say = %CommandsSay{options: %{message: "hi"}}
      emote = %CommandsEmote{options: %{message: "[name] waves"}}

      state = %State{
        npc: %{base_npc() | id: 1, name: "Guard"}
      }

      {:ok, ^state} = Actions.process(state, [say, emote])

      assert_receive {:delayed_actions, [emote]}
    end

    test "no actions to process" do
      state = %State{room_id: 1}

      {:ok, ^state} = Actions.process(state, [])

      refute_received {:delayed_actions, []}
    end
  end

  describe "calculating total delay" do
    test "say action" do
      action = %CommandsSay{delay: 0.5}

      assert Actions.calculate_total_delay(action) == 500
    end

    test "skill action - skill found" do
      start_and_clear_skills()
      insert_skill(create_skill(%{command: "slash", cooldown_time: 750}))

      action = %CommandsSkill{delay: 0.5, options: %{skill: "slash"}}

      assert Actions.calculate_total_delay(action) == 1250
    end

    test "skill action - skill not found" do
      start_and_clear_skills()

      action = %CommandsSkill{delay: 0.5, options: %{skill: "bash"}}

      assert Actions.calculate_total_delay(action) == 500
    end
  end
end
