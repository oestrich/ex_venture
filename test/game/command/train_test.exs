defmodule Game.Command.TrainTest do
  use Data.ModelCase
  doctest Game.Command.Train

  alias Game.Command.Train

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})

    %{state: %{socket: :socket, user: user, save: user.save}}
  end

  describe "list out trainable skills" do
    setup do
      guard = create_npc(%{name: "Guard", is_trainer: true})
      %{guard: guard}
    end

    test "one npc in the room", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:list}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(will train), echo)
    end

    test "hides skills the player already knows", %{state: state, guard: guard} do
      start_and_clear_skills()

      slash = %{name: "Slash", command: "slash"} |> create_skill() |> insert_skill()
      kick = %{name: "Kick", command: "kick"} |> create_skill() |> insert_skill()

      guard = %{guard | trainable_skills: [slash.id, kick.id]}

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      state = %{state | save: %{state.save | skill_ids: [slash.id]}}

      :ok = Train.run({:list}, state)

      [{_, echo}] = @socket.get_echos()
      refute Regex.match?(~r(slash)i, echo)
      assert Regex.match?(~r(kick)i, echo)
    end

    test "hides skills the player is not ready for - too high a level", %{state: state, guard: guard} do
      start_and_clear_skills()

      slash = %{name: "Slash", command: "slash"} |> create_skill() |> insert_skill()
      kick = %{name: "Kick", command: "kick", level: 3} |> create_skill() |> insert_skill()

      guard = %{guard | trainable_skills: [slash.id, kick.id]}

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      state = %{state | save: %{state.save | level: 2}}

      :ok = Train.run({:list}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(slash)i, echo)
      refute Regex.match?(~r(kick)i, echo)
    end

    test "no trainers in the room", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:list}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(no trainers)i, echo)
    end

    test "more than one trainer", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:list}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(more than one), echo)
    end

    test "more than one trainer - by name", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:list, "guard"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Guard.+ will train), echo)
    end

    test "trainer not found - by name", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:list, "guard"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(no trainers), echo)
    end
  end

  describe "training skills" do
    setup do
      start_and_clear_skills()
      slash = %{name: "Slash", command: "slash"} |> create_skill() |> insert_skill()

      guard = create_npc(%{name: "Guard", is_trainer: true})
      guard = %{guard | trainable_skills: [slash.id]}

      %{guard: guard, slash: slash}
    end

    test "training a skill", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      {:update, state} = Train.run({:train, "slash"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(trained success)i, echo)

      assert state.save.skill_ids == [slash.id]
    end

    test "skill not found", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:train, "kick"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(could not find)i, echo)
    end

    test "skill already known", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))
      state = %{state | save: %{state.save | skill_ids: [slash.id]}}

      :ok = Train.run({:train, "slash"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(already known)i, echo)
    end

    test "not high enough level", %{state: state, guard: guard, slash: slash} do
      slash |> Map.put(:level, 4) |> insert_skill()

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))
      state = %{state | save: %{state.save | level: 3}}

      :ok = Train.run({:train, "slash"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(not ready)i, echo)
    end

    test "no trainers in the room", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:train, "slash"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(no trainers)i, echo)
    end

    test "more than one trainer", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:train, "slash"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(more than one), echo)
    end

    test "more than one trainer - by name", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      {:update, state} = Train.run({:train, "slash", :from, "guard"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(trained success)i, echo)

      assert state.save.skill_ids == [slash.id]
    end

    test "trainer not found - by name", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:train, "slash", :from, "unknown"}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(no trainers by that name)i, echo)
    end
  end
end
