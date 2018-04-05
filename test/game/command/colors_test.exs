defmodule Game.Command.ColorsTest do
  use Data.ModelCase
  doctest Game.Command.Colors

  alias Game.ColorCodes
  alias Game.Command.Colors

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    %{state: %{socket: :socket}}
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
end
