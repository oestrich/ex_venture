defmodule Game.Server do
  @moduledoc """
  Handles tick information
  """

  use GenServer

  alias Game.Config
  alias Game.Session
  alias Metrics.PlayerInstrumenter

  @tick_interval 10_000
  @report_players Application.get_env(:ex_venture, :game)[:report_players]

  @doc """
  How often the server will send a :tick
  """
  @spec tick_interval() :: integer
  def tick_interval(), do: @tick_interval

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
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
    case @report_players do
      true ->
        Config.character_names()
        |> PlayerInstrumenter.set_random_character_name_count()

        Session.Registry.player_counts()
        |> PlayerInstrumenter.set_player_count()

      false ->
        :ok
    end

    {:noreply, state}
  end
end
