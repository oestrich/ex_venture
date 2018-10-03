defmodule Game.ExperienceTest do
  use Data.ModelCase
  doctest Game.Experience

  import Test.DamageTypesHelper

  alias Game.Experience

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    save = base_save()
    %{state: session_state(%{user: %{base_user() | save: save}, save: save})}
  end

  test "receive experience and level up", %{state: state} do
    {:ok, :level_up, experience, state} = Experience.apply(state, level: 2, experience_points: 1000)
    assert state.save.level == 2
    assert state.save.experience_points == 1200

    assert experience == 1200
  end

  describe "leveling up" do
    test "on level up, boost stats by your level", %{state: state} do
      state = %{state | save: %{state.save | level_stats: %{strength: 10, intelligence: 9, awareness: 5, vitality: 3}}}

      {:ok, :level_up, _experience, state} = Experience.apply(state, level: 2, experience_points: 1000)

      assert state.save.level_stats == %{}
      assert state.save.stats == %{
        health_points: 57,
        max_health_points: 57,

        skill_points: 58,
        max_skill_points: 58,

        endurance_points: 56,
        max_endurance_points: 56,

        strength: 12,
        agility: 11,
        intelligence: 12,
        awareness: 11,
        willpower: 11,
        vitality: 11,
      }
    end

    test "notifies of new skills that you to use", %{state: state} do
      start_and_clear_skills()

      insert_skill(%{id: 1, level: 1, is_enabled: true, command: "slash", name: "Slash"})
      insert_skill(%{id: 2, level: 2, is_enabled: true, command: "bash", name: "Bash"})

      state = %{state | save: %{state.save | skill_ids: [1, 2]}}

      Experience.notify_new_skills(state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r[can now use], echo)
    end
  end

  test "receive experience and no level up", %{state: state} do
    {:ok, _experience, state} = Experience.apply(state, level: 1, experience_points: 901)

    assert state.save.level == 1
    assert state.save.experience_points == 901
  end

  describe "tracking effect usage" do
    setup do
      save = %{
        level_stats: %{},
      }

      start_and_clear_damage_types()

      insert_damage_type(%{key: "arcane", stat_modifier: :intelligence})
      insert_damage_type(%{key: "slashing", stat_modifier: :strength})

      %{save: save}
    end

    test "damage effects - strength", %{save: save} do
      effect = %{kind: "damage", type: "slashing", amount: 10}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.strength == 1
    end

    test "damage effects - intelligence", %{save: save} do
      effect = %{kind: "damage", type: "arcane", amount: 10}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.intelligence == 1
    end

    test "damage over time effects - strength", %{save: save} do
      effect = %{kind: "damage/over-time", type: "slashing", amount: 10}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.strength == 1
    end

    test "damage over time effects - intelligence", %{save: save} do
      effect = %{kind: "damage/over-time", type: "arcane", amount: 10}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.intelligence == 1
    end

    test "recover - awareness", %{save: save} do
      effect = %{kind: "recover"}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.awareness == 1
    end
  end
end
