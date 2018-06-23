defmodule Game.Command.RecallTest do
  use Data.ModelCase
  doctest Game.Command.Recall

  alias Game.Command.Recall

  @socket Test.Networking.Socket
  @room Test.Game.Room
  @zone Test.Game.Zone

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user, save: user.save}}
  end

  describe "recalling to a graveyard" do
    test "teleports to the zone's graveyard", %{state: state} do
      @room.set_room(@room._room())
      @zone.set_graveyard({:ok, 2})

      {:update, state} = Recall.run({}, state)

      assert state.save.stats.endurance_points == 0
      assert_received {:"$gen_cast", {:teleport, 2}}
    end

    test "not enough endurance", %{state: state} do
      %{save: save}  = state

      state = %{state | save: %{save | stats: %{save.stats | endurance_points: 5, max_endurance_points: 10}}}

      :ok = Recall.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r{do not have enough endurance}, echo)
    end

    test "zone does not have a graveyard", %{state: state} do
      @room.set_room(@room._room())
      @zone.set_graveyard({:error, :no_graveyard})

      :ok = Recall.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r{you cannot recall here}i, echo)
    end
  end
end
