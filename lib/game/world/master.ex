defmodule Game.World.Master do
  @moduledoc """
  Master process for the world

  Help orchestrate startup of zones
  """

  use GenServer

  alias Game.World
  alias Game.Zone

  require Logger

  def start_zone(pid, zone) do
    GenServer.cast(pid, {:start, zone})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ok = :pg2.create(:world)
    :ok = :pg2.join(:world, self())

    Process.send_after(self(), :elect, 5_000 + :rand.uniform(5_000))

    {:ok, %{leader: nil}}
  end

  def handle_cast({:start, zone}, state) do
    Logger.info("Starting zone #{zone.id}")
    World.start_child(zone)
    {:noreply, state}
  end

  def handle_info(:ping, state) do
    IO.puts "PONG - #{inspect(self())} - #{inspect(state)}"
    {:noreply, state}
  end

  def handle_info(:elect, state) do
    case state.leader do
      nil ->
        :world
        |> :pg2.get_members()
        |> Enum.map(fn pid ->
          send(pid, {:leader, self()})
        end)

        Process.send_after(self(), :start_zones, 3_000)

      _ ->
        {:leader, :elected}
    end

    {:noreply, state}
  end

  def handle_info({:leader, pid}, state) do
    case state.leader do
      nil ->
        Logger.info("Selecing a new leader #{inspect(self())}")

        {:noreply, %{state | leader: pid}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(:start_zones, state) do
    case state.leader == self() do
      true ->
        Logger.info("Starting zones")
        start_zones()

      false ->
        :error
    end

    {:noreply, state}
  end

  defp start_zones() do
    members = :pg2.get_members(:world)
    IO.inspect members

    Zone.all()
    |> Enum.with_index()
    |> Enum.map(fn {zone, index} ->
      member = Enum.at(members, rem(index, length(members)))
      __MODULE__.start_zone(member, zone)
    end)
  end
end
