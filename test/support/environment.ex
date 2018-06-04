defmodule Test.Game.Environment do
  alias Test.Game.Room

  def look(id) do
    Room.start_link()

    Agent.get(Room, fn (state) ->
      case state.offline do
        true ->
          {:error, :room_offline}

        false ->
          {:ok, Map.get(state.rooms, id, state.room)}
      end
    end)
  end
end
