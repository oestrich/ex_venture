defmodule Game.Command.EmoteTest do
  use Data.ModelCase
  doctest Game.Command.Emote

  alias Game.Command.Emote
  alias Game.Message

  @room Test.Game.Room

  setup do
    @room.clear_emotes()
    %{socket: :socket, user: %{name: "user"}}
  end

  test "send an emote to the room", %{socket: socket, user: user} do
    :ok = Emote.run({"does something"}, %{socket: socket, user: user, save: %{room_id: 1}})

    assert @room.get_emotes() == [{1, Message.emote(user, "does something")}]
  end
end
