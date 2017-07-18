defmodule Game.Server do
  use GenServer

  alias Game.Session

  @tick_interval 2000

  def tick_interval(), do: @tick_interval

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, nil}
  end

  def handle_info(:tick, state) do
    time = Timex.now()

    Session.Registry.connected_players
    |> Enum.map(fn ({session, _}) ->
      session |> Session.tick(time)
    end)

    {:noreply, state}
  end
end
