defmodule Game.Server do
  @moduledoc """
  Handles tick information
  """

  use GenServer

  alias Game.Session
  alias Metrics.PlayerInstrumenter

  @tick_interval 2000

  @doc """
  How often the server will send a :tick
  """
  @spec tick_interval() :: integer
  def tick_interval(), do: @tick_interval

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def started_at() do
    GenServer.call(__MODULE__, :started_at)
  end

  @doc false
  def init(_) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, %{started_at: Timex.now()}}
  end

  def handle_call(:started_at, _from, state) do
    {:reply, state.started_at, state}
  end

  def handle_info(:tick, state) do
    Session.Registry.connected_players()
    |> Enum.map(& &1.user)
    |> PlayerInstrumenter.set_player_count()

    {:noreply, state}
  end
end
