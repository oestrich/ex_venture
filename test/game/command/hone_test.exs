defmodule Game.Command.HoneTest do
  use ExVenture.CommandCase

  alias Data.Proficiency
  alias Game.Command.Hone

  doctest Hone

  setup do
    save =
      base_save()
      |> Map.put(:experience_points, 1200)
      |> Map.put(:spent_experience_points, 100)

    %{state: session_state(%{user: %{save: save}, save: save})}
  end

  describe "help" do
    test "list what stats you can raise", %{state: state} do
      :ok = Hone.run({:help}, state)

      assert_socket_echo "strength"
    end
  end

  describe "honing your skills" do
    test "spending your xp to raise a stat", %{state: state} do
      {:update, state} = Hone.run({:hone, "strength"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.strength == 11

      assert_socket_echo "honed your strength"
    end

    test "hone willpower", %{state: state} do
      {:update, state} = Hone.run({:hone, "willpower"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.willpower == 11

      assert_socket_echo "honed your willpower"
    end

    test "hone health points", %{state: state} do
      {:update, state} = Hone.run({:hone, "health points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_health_points == 55

      assert_socket_echo "honed your health"
    end

    test "hone skill points", %{state: state} do
      {:update, state} = Hone.run({:hone, "skill points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_skill_points == 55

      assert_socket_echo "honed your skill"
    end

    test "hone endurance points", %{state: state} do
      {:update, state} = Hone.run({:hone, "endurance points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_endurance_points == 55

      assert_socket_echo "honed your endurance"
    end

    test "not enough xp left over", %{state: state} do
      state = %{state | save: %{state.save | spent_experience_points: 1100}}

      :ok = Hone.run({:hone, "strength"}, state)

      assert_socket_echo "do not have enough"
    end

    test "bad stat", %{state: state} do
      :ok = Hone.run({:hone, "unknown"}, state)

      assert_socket_echo "unknown"
    end
  end

  describe "honing proficiencies" do
    setup %{state: state} do
      start_and_clear_proficiencies()
      proficiency = create_proficiency(%{name: "Swimming"})
      insert_proficiency(proficiency)

      save = %{state.save | proficiencies: [%Proficiency.Instance{id: proficiency.id, ranks: 5}]}
      state = %{state | save: save}

      %{state: state, proficiency: proficiency}
    end

    test "hone proficiency", %{state: state} do
      {:update, state} = Hone.run({:hone, "swimming"}, state)

      assert state.save.spent_experience_points == 400

      instance = List.first(state.save.proficiencies)
      assert instance.ranks == 6

      assert_socket_echo "honed your swimming"
    end

    test "raising a proficiency you don't have", %{state: state} do
      save = %{state.save | proficiencies: []}
      state = %{state | save: save}

      :ok = Hone.run({:hone, "swimming"}, state)

      assert_socket_echo "do not know"
    end

    test "not enough experience to spend", %{state: state} do
      state = %{state | save: %{state.save | spent_experience_points: 1100}}

      :ok = Hone.run({:hone, "swimming"}, state)

      assert_socket_echo "do not have enough"
    end
  end
end
