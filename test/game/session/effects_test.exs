defmodule Game.Session.EffectsTest do
  use ExVenture.SessionCase

  import Test.DamageTypesHelper

  alias Game.Session.Effects

  setup do
    start_and_clear_damage_types()

    insert_damage_type(%{
      key: "slashing",
      stat_modifier: :strength,
      boost_ratio: 20,
      reverse_stat: :agility,
      reverse_boost: 20,
    })

    user = %{id: 2, name: "user", save: base_save(), class: class_attributes(%{})}
    stats = %{user.save.stats | health_points: 25, agility: 10}

    state = session_state(%{
      user: user,
      save: %{user.save | room_id: 1, experience_points: 10, stats: stats},
      is_targeting: MapSet.new(),
    })

    %{state: state}
  end

  describe "continuous effects" do
    setup %{state: state} do
      from = {:npc, %{id: 1, name: "Bandit"}}
      effect = %{id: :id, kind: "damage/over-time", type: "slashing", every: 10, count: 3, amount: 15}
      state = %{state | continuous_effects: [{from, effect}]}

      %{state: state, effect: effect, from: from}
    end

    test "applying effects with continuous effects", %{state: state, effect: effect} do
      state = Effects.handle_continuous_effect(state, effect.id)

      assert state.save.stats.health_points == 15
      assert_socket_echo "10 slashing damage is dealt"

      [{_, %{id: :id, count: 2}}] = state.continuous_effects

      effect_id = effect.id
      assert_receive {:continuous_effect, ^effect_id}
    end

    test "handles death", %{state: state, effect: effect, from: from} do
      start_room(%{id: state.save.room_id})
      start_zone(%{id: 1})

      effect = %{effect | amount: 38}
      state = %{state | continuous_effects: [{from, effect}]}

      state = Effects.handle_continuous_effect(state, :id)
      assert state.save.stats.health_points == -1

      assert state.continuous_effects == []
    end

    test "does not send another message if last count", %{state: state, effect: effect, from: from} do
      effect = %{effect | count: 1}
      state = %{state | continuous_effects: [{from, effect}]}

      state = Effects.handle_continuous_effect(state, effect.id)
      [] = state.continuous_effects

      effect_id = effect.id
      refute_receive {:continuous_effect, ^effect_id}, 50
    end

    test "does nothing if effect is not found", %{state: state} do
      ^state = Effects.handle_continuous_effect(state, :notfound)
    end
  end
end
