defmodule Game.Command.EmoteTest do
  use Data.ModelCase
  doctest Game.Command.Emote

  alias Game.Command.Emote
  alias Game.Message

  @room Test.Game.Room

  setup do
    @room.clear_emotes()

    %{state: session_state(%{user: base_user()})}
  end

  test "send an emote to the room", %{state: state} do
    :ok = Emote.run({"does something"}, state)

    assert @room.get_emotes() == [{1, Message.emote(state.character, "does something")}]
  end
end
