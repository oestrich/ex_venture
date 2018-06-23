defmodule Game.Command.HoneTest do
  use Data.ModelCase
  doctest Game.Command.Hone

  alias Game.Command.Hone
  alias Game.Session.State

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()

    save =
      base_save()
      |> Map.put(:experience_points, 1200)
      |> Map.put(:spent_experience_points, 100)

    state = %State{
      state: "active",
      mode: "commands",
      socket: :socket,
      user: %{save: save},
      save: save,
    }

    %{state: state}
  end

  describe "help" do
    test "list what stats you can raise", %{state: state} do
      :ok = Hone.run({:help}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/strength/i, echo)
    end
  end

  describe "honing your skills" do
    test "spending your xp to raise a stat", %{state: state} do
      {:update, state} = Hone.run({:hone, "strength"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.strength == 11

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/honed your strength/i, echo)
    end

    test "hone willpower", %{state: state} do
      {:update, state} = Hone.run({:hone, "willpower"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.willpower == 11

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/honed your willpower/i, echo)
    end

    test "hone health points", %{state: state} do
      {:update, state} = Hone.run({:hone, "health points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_health_points == 55

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/honed your health/i, echo)
    end

    test "hone skill points", %{state: state} do
      {:update, state} = Hone.run({:hone, "skill points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_skill_points == 55

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/honed your skill/i, echo)
    end

    test "hone endurance points", %{state: state} do
      {:update, state} = Hone.run({:hone, "endurance points"}, state)

      assert state.save.spent_experience_points == 400
      assert state.save.stats.max_endurance_points == 55

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/honed your endurance/i, echo)
    end

    test "not enough xp left over", %{state: state} do
      state = %{state | save: %{state.save | spent_experience_points: 1100}}

      :ok = Hone.run({:hone, "strength"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/do not have enough/i, echo)
    end

    test "bad stat", %{state: state} do
      :ok = Hone.run({:hone, "unknown"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/unknown/i, echo)
    end
  end
end
