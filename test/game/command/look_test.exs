defmodule Game.Command.LookTest do
  use Data.ModelCase
  doctest Game.Command.Look

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Item
  alias Game.Command.Look
  alias Game.Environment

  describe "normal room" do
    setup do
      start_and_clear_items()
      item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
      insert_item(item)

      bandit = %{
        id: 1,
        name: "Bandit",
        extra: %{
          original_id: 1,
          description: "bandit description",
          status_line: "[name] is here."
        },
      }

      room = %{
        items: [Item.instantiate(item)],
        npcs: [bandit],
        players: [%{id: 1, name: "Player"}],
        features: [%{key: "log", short_description: "log", description: "a log"}],
        zone: %{id: 10, name: "Zone"}
      }
      @room.set_room(Map.merge(@room._room(), room))

      @socket.clear_messages()

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      %{state: session_state(%{user: user, character: character})}
    end

    test "view room information", %{state: state} do
      :ok = Look.run({}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Hallway), look)
      assert Regex.match?(~r(Exits), look)
      assert Regex.match?(~r(Items), look)

      assert Enum.any?(@socket.get_push_gmcps(), fn ({_socket, module, _}) -> module == "Zone.Map" end)
    end

    test "view room information - the room is offline", %{state: state} do
      @room.set_room(:offline)

      {:error, :room_offline} = Look.run({}, state)

      assert @socket.get_echos() == []
    end

    test "looking at an item", %{state: state} do
      :ok = Look.run({:other, "short sword"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(A simple blade), look)
    end

    test "looking at an npc", %{state: state} do
      :ok = Look.run({:other, "bandit"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(bandit description), look)
    end

    test "looking at a player", %{state: state} do
      :ok = Look.run({:other, "player"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Player), look)
    end

    test "looking in a direction", %{state: state} do
      :ok = Look.run({:direction, "north"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Hallway), look)
    end

    test "looking at a room feature", %{state: state} do
      :ok = Look.run({:other, "log"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(a log), look)
    end

    test "could not find the name", %{state: state} do
      :ok = Look.run({:other, "unknown"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Could not find), look)
    end
  end

  describe "overworld" do
    setup do
      room = %Environment.State.Overworld{
        id: "overworld:1:1,1",
        exits: [%{direction: "west"}],
      }
      @room.set_room(room)

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      save = %{character.save | room_id: "overworld:1:1,1"}
      %{state: session_state(%{user: user, character: character, save: save})}
    end

    test "looking in the overworld", %{state: state} do
      :ok = Look.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Exits), echo)
    end
  end
end
