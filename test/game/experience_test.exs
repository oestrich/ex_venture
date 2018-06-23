defmodule Game.ExperienceTest do
  use Data.ModelCase
  doctest Game.Experience

  import Test.DamageTypesHelper

  alias Game.Experience

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    save = base_save()
    %{socket: :socket, user: %{save: save}, save: save}
  end

  test "receive experience and level up", state do
    {:ok, :level_up, experience, state} = Experience.apply(state, level: 2, experience_points: 1000)
    assert state.save.level == 2
    assert state.save.experience_points == 1200

    assert experience == 1200
  end

  test "on level up, boost stats by your level", state do
    state = %{state | save: %{state.save | level_stats: %{strength: 10, intelligence: 9, wisdom: 5}}}

    {:ok, :level_up, _experience, state} = Experience.apply(state, level: 2, experience_points: 1000)

    assert state.save.level_stats == %{}
    assert state.save.stats == %{
      health_points: 57,
      max_health_points: 57,

      skill_points: 58,
      max_skill_points: 58,

      endurance_points: 12,
      max_endurance_points: 12,

      strength: 12,
      dexterity: 11,
      constitution: 11,
      intelligence: 12,
      wisdom: 11,
    }
  end

  test "receive experience and no level up", state do
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

    test "recover - wisdom", %{save: save} do
      effect = %{kind: "recover"}

      save = Experience.track_stat_usage(save, [effect])

      assert save.level_stats.wisdom == 1
    end
  end
end
