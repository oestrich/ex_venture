defmodule Game.ExperienceTest do
  use Data.ModelCase
  doctest Game.Experience

  alias Game.Experience

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{socket: :socket, save: base_save()}
  end

  test "receive experience and level up", state do
    state = Experience.apply(state, level: 2, experience_points: 1000)
    assert state.save.level == 2
    assert state.save.experience_points == 1200

    [{:socket, exp_echo}, {:socket, lvl_echo}] = @socket.get_echos()
    assert Regex.match?(~r(1200 experience points), exp_echo)
    assert Regex.match?(~r(You leveled), lvl_echo)
  end

  test "on level up, boost stats by your level", state do
    state = Experience.apply(state, level: 2, experience_points: 1000)

    assert state.save.stats == %{
      health_points: 52,
      max_health_points: 52,
      skill_points: 52,
      max_skill_points: 52,
      strength: 12,
      dexterity: 12,
      constitution: 12,
      intelligence: 12,
      wisdom: 12,
      move_points: 12,
      max_move_points: 12,
    }
  end

  test "receive experience and no level up", state do
    state = Experience.apply(state, level: 1, experience_points: 901)
    assert state.save.level == 1
    assert state.save.experience_points == 901

    [{:socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(901 experience points), echo)
  end
end
