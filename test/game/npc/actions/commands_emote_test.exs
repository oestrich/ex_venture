defmodule Game.NPC.Actions.CommandsEmoteTest do
  use ExVenture.NPCCase

  alias Data.Events.Actions
  alias Game.NPC.Actions.CommandsEmote

  doctest CommandsEmote

  setup do
    npc = npc_attributes(%{
      id: 1,
      status_line: "[name] is here.",
      status_listen: nil,
    })

    %{state: %State{npc: npc, room_id: 1}}
  end

  describe "acting" do
    test "speaks to the room", %{state: state} do
      action = %Actions.CommandsEmote{
        options: %{message: "Hello"}
      }

      {:ok, ^state} = CommandsEmote.act(state, action)

      assert_emote "hello"
    end

    test "handles status updates", %{state: state} do
      action = %Actions.CommandsEmote{
        options: %{
          message: "[name] claps.",
          status_key: "clapping",
          status_line: "[name] is clapping",
          status_listen: "[name] is clapping their hands"
        }
      }

      {:ok, state} = CommandsEmote.act(state, action)

      assert state.status.key == "clapping"
      assert state.status.line == "[name] is clapping"
      assert state.status.listen == "[name] is clapping their hands"
    end

    test "resets status", %{state: state} do
      action = %Actions.CommandsEmote{
        options: %{
          message: "[name] claps.",
          status_reset: true,
        }
      }

      {:ok, state} = CommandsEmote.act(state, action)

      assert state.status.key == "start"
      assert state.status.line == "[name] is here."
      assert is_nil(state.status.listen)
    end
  end
end
