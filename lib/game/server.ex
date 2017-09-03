defmodule Game.Server do
  @moduledoc """
  Handles tick information
  """

  use GenServer

  alias Game.NPC
  alias Game.Session
  alias Game.Zone
  alias Game.World

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

  @doc false
  def init(_) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, nil}
  end

  def handle_info(:tick, state) do
    time = Timex.now()

    Session.Registry.connected_players
    |> Enum.each(fn ({session, _}) ->
      session |> Session.tick(time)
    end)

    World.zones() |> Enum.each(&(Zone.tick(&1, time)))

    {:noreply, state}
  end
end
