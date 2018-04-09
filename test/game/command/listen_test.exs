defmodule Game.Command.ListenTest do
  use Data.ModelCase
  doctest Game.Command.Listen

  alias Game.Command.Listen

  @room Test.Game.Room
  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    save = base_save()
    %{state: %{socket: :socket, user: %{save: save}, save: save}}
  end

  describe "listening to the current room" do
    setup do
      room = %{
        listen: "Sounds of water trickling can be heard",
        features: [
          %{key: "flag", listen: "A flag is flapping in the breeze"},
        ],
      }
      @room.set_room(Map.merge(@room._room(), room))

      :ok
    end

    test "room contains no listening text", %{state: state} do
      @room.set_room(@room._room())

      :ok = Listen.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Nothing can be heard/, echo)
    end

    test "includes the room listen text", %{state: state} do
      :ok = Listen.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/trickling/, echo)
    end

    test "includes the room's features", %{state: state} do
      :ok = Listen.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/flapping/, echo)
    end
  end

  describe "listening in a direction" do
    setup do
      room = %{id: 1, exits: [%{north_id: 2, south_id: 1}]}
      @room.set_room(Map.merge(@room._room(), room), multiple: true)

      room = %{
        id: 2,
        listen: "Sounds of water trickling can be heard",
        features: [
          %{key: "flag", listen: "A flag is flapping in the breeze"},
        ],
      }
      @room.set_room(Map.merge(@room._room(), room), multiple: true)

      :ok
    end

    test "includes the room listen text", %{state: state} do
      :ok = Listen.run({:north}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/trickling/, echo)
    end

    test "nothing in specified direction", %{state: state} do
      :ok = Listen.run({:south}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/no exit/i, echo)
    end
  end
end
