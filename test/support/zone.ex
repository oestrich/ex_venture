defmodule Test.Game.Zone do
  alias Data.Zone

  def start_link() do
    Agent.start_link(fn () -> %{zone: _zone()} end, name: __MODULE__)
  end

  def _zone() do
    %Zone{
      name: "Hallway",
    }
  end

  def set_zone(zone) do
    start_link()

    Agent.update(__MODULE__, fn (state) ->
      state |> Map.put(:zone, zone)
    end)
  end

  def map(_id, _player_at, _opts \\ []) do
    "    [ ]    \n[ ] [X] [ ]\n    [ ]    "
  end

  def graveyard(_id) do
    start_link()
    Agent.get(__MODULE__, fn (state) ->
      case state do
        %{graveyard: response} when response != nil ->
          response
        _ ->
          {:ok, state.zone.graveyard_id}
      end
    end)
  end

  def set_graveyard(response) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      state |> Map.put(:graveyard, response)
    end)
  end

  def crash(_zone_id) do
    :ok
  end
end
