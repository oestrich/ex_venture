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
end
