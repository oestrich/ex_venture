defmodule Game.Session.EffectsTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session.Effects
  alias Game.Session.State

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    socket = :socket
    @socket.clear_messages
    @room.clear_update_characters()

    user = %{id: 2, name: "user", class: class_attributes(%{})}
    stats = %{health: 25}
    %{state: %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: stats}, is_targeting: MapSet.new()}}
  end

  describe "continuous effects" do
    setup %{state: state} do
      effect = %{id: :id, kind: "damage/over-time", type: :slashing, every: 10, count: 3, amount: 10}
      state = %{state | continuous_effects: [effect]}
      %{state: state, effect: effect}
    end

    test "applying effects with continuous effects", %{state: state, effect: effect} do
      state = Effects.handle_continuous_effect(state, effect.id)

      assert state.save.stats.health == 15
      assert_received {:"$gen_cast", {:echo, ~s(10 slashing damage is dealt.)}}

      [%{id: :id, count: 2}] = state.continuous_effects

      effect_id = effect.id
      assert_receive {:continuous_effect, ^effect_id}
    end

    test "handles death", %{state: state, effect: effect} do
      effect = %{effect | amount: 26}
      state = %{state | continuous_effects: [effect]}

      state = Effects.handle_continuous_effect(state, :id)
      assert state.save.stats.health == -1

      assert state.continuous_effects == []
    end

    test "does not send another message if last count", %{state: state, effect: effect} do
      effect = %{effect | count: 1}
      state = %{state | continuous_effects: [effect]}

      state = Effects.handle_continuous_effect(state, effect.id)
      [] = state.continuous_effects

      effect_id = effect.id
      refute_receive {:continuous_effect, ^effect_id}
    end

    test "does nothing if effect is not found", %{state: state} do
      ^state = Effects.handle_continuous_effect(state, :notfound)
    end
  end
end
