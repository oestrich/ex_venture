defmodule Game.Command.TrainTest do
  use ExVenture.CommandCase

  alias Data.ActionBar
  alias Game.Character
  alias Game.Command.Train

  doctest Train

  @room Test.Game.Room

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)
    save = %{character.save | level: 2, experience_points: 1100}
    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "list out trainable skills" do
    setup do
      guard = create_npc(%{name: "Guard", is_trainer: true})
      %{guard: Character.Simple.from_npc(guard)}
    end

    test "one npc in the room", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:list}, state)

      assert_socket_echo "will train"
    end

    test "hides skills the player already knows", %{state: state, guard: guard} do
      start_and_clear_skills()

      slash = %{name: "Slash", command: "slash"} |> create_skill() |> insert_skill()
      kick = %{name: "Kick", command: "kick"} |> create_skill() |> insert_skill()

      guard = %{guard | extra: %{guard.extra | trainable_skills: [slash.id, kick.id]}}

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      state = %{state | save: %{state.save | skill_ids: [slash.id]}}

      :ok = Train.run({:list}, state)

      assert_socket_echo "kick"
    end

    test "hides skills the player is not ready for - too high a level", %{state: state, guard: guard} do
      start_and_clear_skills()

      slash = %{name: "Slash", command: "slash"} |> create_skill() |> insert_skill()
      kick = %{name: "Kick", command: "kick", level: 3} |> create_skill() |> insert_skill()

      guard = %{guard | extra: %{guard.extra | trainable_skills: [slash.id, kick.id]}}

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      state = %{state | save: %{state.save | level: 2}}

      :ok = Train.run({:list}, state)

      assert_socket_echo "slash"
    end

    test "no trainers in the room", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:list}, state)

      assert_socket_echo "no trainers"
    end

    test "more than one trainer", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      master = Character.Simple.from_npc(master)
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:list}, state)

      assert_socket_echo "more than one"
    end

    test "more than one trainer - by name", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:list, "guard"}, state)

      assert_socket_echo "Guard.+ will train"
    end

    test "trainer not found - by name", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:list, "guard"}, state)

      assert_socket_echo "no trainers"
    end
  end

  describe "training skills" do
    setup do
      start_and_clear_skills()
      slash = %{name: "Slash", command: "slash", level: 2} |> create_skill() |> insert_skill()

      guard = create_npc(%{name: "Guard", is_trainer: true})
      guard = Character.Simple.from_npc(guard)
      guard = %{guard | extra: %{guard.extra | trainable_skills: [slash.id]}}

      %{guard: guard, slash: slash}
    end

    test "training a skill", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      {:update, state} = Train.run({:train, "slash"}, state)

      assert_socket_echo "trained success"

      assert state.save.skill_ids == [slash.id]
      assert state.save.spent_experience_points == 1000
      assert state.save.actions == [%ActionBar.SkillAction{id: slash.id}]
    end

    test "skill not found", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:train, "kick"}, state)

      assert_socket_echo "could not find"
    end

    test "skill already known", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))
      state = %{state | save: %{state.save | skill_ids: [slash.id]}}

      :ok = Train.run({:train, "slash"}, state)

      assert_socket_echo "already known"
    end

    test "not high enough level", %{state: state, guard: guard, slash: slash} do
      slash |> Map.put(:level, 4) |> insert_skill()

      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))
      state = %{state | save: %{state.save | level: 3}}

      :ok = Train.run({:train, "slash"}, state)

      assert_socket_echo "not ready"
    end

    test "not enough xp left to spend", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))
      state = %{state | save: %{state.save | spent_experience_points: 900, experience_points: 1000}}

      :ok = Train.run({:train, "slash"}, state)

      assert_socket_echo "do not have enough"
    end

    test "no trainers in the room", %{state: state} do
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Train.run({:train, "slash"}, state)

      assert_socket_echo "no trainers"
    end

    test "more than one trainer", %{state: state, guard: guard} do
      master = create_npc(%{name: "Guard", is_trainer: true})
      master = Character.Simple.from_npc(master)
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard, master]}))

      :ok = Train.run({:train, "slash"}, state)

      assert_socket_echo "more than one"
    end

    test "more than one trainer - by name", %{state: state, guard: guard, slash: slash} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      {:update, state} = Train.run({:train, "slash", :from, "guard"}, state)

      assert_socket_echo "trained success"

      assert state.save.skill_ids == [slash.id]
    end

    test "trainer not found - by name", %{state: state, guard: guard} do
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Train.run({:train, "slash", :from, "unknown"}, state)

      assert_socket_echo "no trainers by that name"
    end
  end
end
