defmodule Game.Command.EmoteTest do
  use ExVenture.CommandCase

  alias Game.Command.Emote

  doctest Emote

  setup do
    user = base_user()
    character = base_character(user)

    %{state: session_state(%{user: user, character: character})}
  end

  test "send an emote to the room", %{state: state} do
    :ok = Emote.run({"does something"}, state)

    assert_emote "does something"
  end
end
