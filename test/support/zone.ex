defmodule Test.Game.Zone do
  alias Data.Zone
  alias Test.Game.Zone.FakeZone

  def _zone() do
    %Zone{
      name: "Hallway",
    }
  end

  def map(_id, _player_at, _opts \\ []) do
    "    [ ]    \n[ ] [X] [ ]\n    [ ]    "
  end

  def set_zone(zone) do
    {:ok, pid} = FakeZone.start_link(zone)
    Process.put({:zone, zone.id}, pid)
  end

  def set_graveyard(zone, response) do
    GenServer.call(Process.get({:zone, zone.id}), {:put, {:graveyard, response}})
  end

  def graveyard(id) do
    GenServer.call(Process.get({:zone, id}), {:graveyard})
  end

  def crash(_zone_id) do
    :ok
  end

  defmodule FakeZone do
    use GenServer

    def start_link(zone) do
      GenServer.start_link(__MODULE__, [zone: zone, caller: self()])
    end

    @impl true
    def init(opts) do
      state = %{
        zone: opts[:zone],
        caller: opts[:caller],
        responses: %{
          graveyard: {:error, :no_graveyard}
        }
      }

      {:ok, state}
    end

    @impl true
    def handle_call({:put, {field, response}}, _from, state) do
      responses = Map.put(state.responses, field, response)
      state = Map.put(state, :responses, responses)

      {:reply, :ok, state}
    end

    def handle_call({:graveyard}, _from, state) do
      {:reply, state.responses[:graveyard], state}
    end
  end

  defmodule Helpers do
    alias Test.Game.Zone

    def start_zone(zone) do
      Zone.set_zone(zone)
    end

    def put_zone_graveyard(zone, response) do
      Zone.set_graveyard(zone, response)
    end
  end
end
