defmodule Game.Command.EmoteTest do
  use Data.ModelCase

  alias Game.Command
  alias Game.Message

  @room Test.Game.Room

  setup do
    @room.clear_emotes()
    %{session: :session, socket: :socket, user: %{name: "user"}}
  end

  test "send an emote to the room", %{socket: socket, session: session, user: user} do
    :ok = Command.Emote.run({"does something"}, session, %{socket: socket, user: user, save: %{room_id: 1}})

    assert @room.get_emotes() == [{1, Message.emote(user, "does something")}]
  end
end
