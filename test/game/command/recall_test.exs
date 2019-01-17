defmodule Game.Command.RecallTest do
  use ExVenture.CommandCase

  alias Game.Command.Recall

  doctest Recall

  @zone Test.Game.Zone

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    %{state: session_state(%{user: user, character: character, save: character.save})}
  end

  describe "recalling to a graveyard" do
    test "teleports to the zone's graveyard", %{state: state} do
      start_room(%{})
      @zone.set_graveyard({:ok, 2})

      {:update, state} = Recall.run({}, state)

      assert state.save.stats.endurance_points == 0
      assert_received {:"$gen_cast", {:teleport, 2}}
    end

    test "not enough endurance", %{state: state} do
      %{save: save}  = state

      state = %{state | save: %{save | stats: %{save.stats | endurance_points: 5, max_endurance_points: 10}}}

      :ok = Recall.run({}, state)

      assert_socket_echo "do not have enough endurance"
    end

    test "zone does not have a graveyard", %{state: state} do
      start_room(%{})
      @zone.set_graveyard({:error, :no_graveyard})

      :ok = Recall.run({}, state)

      assert_socket_echo "you cannot recall"
    end
  end
end
