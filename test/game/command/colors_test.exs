defmodule Game.Command.ColorsTest do
  use Data.ModelCase
  doctest Game.Command.Colors

  alias Game.ColorCodes
  alias Game.Command.Colors

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    save = base_save()
    %{state: %{socket: :socket, user: %{save: save}, save: save}}
  end

  describe "viewing a list of colors" do
    test "built in colors", %{state: state} do
      {:paginate, echo, _state} = Colors.run({:list}, state)

      assert Regex.match?(~r/green/, echo)
    end

    test "map colors", %{state: state} do
      {:paginate, echo, _state} = Colors.run({:list}, state)

      assert Regex.match?(~r/light-grey/, echo)
    end

    test "custom colors", %{state: state} do
      ColorCodes.insert(%{key: "pink"})

      {:paginate, echo, _state} = Colors.run({:list}, state)

      assert Regex.match?(~r/pink/, echo)
    end
  end

  describe "resetting your base colors" do
    test "includes npcs, exits, etc in their current colors", %{state: state} do
      state = %{state | save: %{state.save | config: %{color_npc: "green"}}}

      {:update, state} = Colors.run({:reset}, state)

      refute Map.has_key?(state.save.config, :color_npc)
    end
  end

  describe "viewing semantic colors" do
    test "includes npcs, exits, etc in their current colors", %{state: state} do
      {:paginate, echo, _state} = Colors.run({:semantic}, state)

      assert Regex.match?(~r/npc/i, echo)
    end
  end
end
