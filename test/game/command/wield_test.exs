defmodule Game.Command.WieldTest do
  use Data.ModelCase
  doctest Game.Command.Wield

  alias Data.Save
  alias Game.Command
  alias Game.Items

  @socket Test.Networking.Socket

  setup do
    Items.start_link
    Agent.update(Items, fn (_) ->
      %{
        1 => %{id: 1, name: "Sword", keywords: []},
        2 => %{id: 2, name: "Shield", keywords: []},
      }
    end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "wield an item", %{session: session, socket: socket} do
    save = %Save{item_ids: [1]}
    {:update, state} = Command.Wield.run(["sword"], session, %{socket: socket, save: save})

    assert state.save.wielding == %{right: 1}
    assert state.save.item_ids == []

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Sword is now in your right hand), look)
  end

  test "wield an item - puts current item back in inventory", %{session: session, socket: socket} do
    save = %Save{wielding: %{right: 1}, item_ids: [2]}
    {:update, state} = Command.Wield.run(["shield"], session, %{socket: socket, save: save})

    assert state.save.wielding == %{right: 2}
    assert state.save.item_ids == [1]

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Shield is now in your right hand), look)
  end

  test "item not found", %{session: session, socket: socket} do
    save = %Save{item_ids: [1]}
    Command.Wield.run(["polearm"], session, %{socket: socket, save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r("polearm" could not be found), look)
  end
end
