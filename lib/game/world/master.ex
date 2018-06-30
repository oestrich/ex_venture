defmodule Game.World.Master do
  @moduledoc """
  Master process for the world

  Help orchestrate startup of zones
  """

  use GenServer

  alias Game.World.ZoneController
  alias Game.Zone

  require Logger

  @group :world_leaders
  @table :world_leader

  @start_world Application.get_env(:ex_venture, :game)[:world]

  @doc """
  The local node was selected as a leader
  """
  def leader_selected() do
    if @start_world do
      GenServer.cast(__MODULE__, :rebalance_zones)
    end

    Gossip.start_socket()
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Check if the world is online
  """
  @spec is_world_online?() :: boolean()
  def is_world_online?() do
    case :ets.lookup(@table, :world_online) do
      [{_, status}] ->
        status

      _ ->
        false
    end
  end

  def init(_) do
    :ok = :pg2.create(@group)
    :ok = :pg2.join(@group, self())

    :ets.new(@table, [:set, :protected, :named_table])

    {:ok, %{}}
  end

  # This is started by the raft
  def handle_cast(:rebalance_zones, state) do
    Logger.info("Starting zones")
    rebalance_zones()

    members = :pg2.get_members(@group)

    Enum.each(members, fn member ->
      send(member, {:set, :world_online, true})
    end)

    {:noreply, state}
  end

  def handle_info({:set, :world_online, status}, state) do
    :ets.insert(@table, {:world_online, status})
    Logger.info("World is online? #{status}")
    {:noreply, state}
  end

  defp rebalance_zones() do
    members = :pg2.get_members(:world)

    hosted_zones = get_member_zones(members)

    zones = Zone.all()

    zone_count = length(zones)
    member_count = length(members)
    max_zones = round(Float.ceil(zone_count / member_count))

    zones
    |> Enum.reject(fn zone ->
      Enum.any?(hosted_zones, fn {_, zone_ids} ->
        Enum.member?(zone_ids, zone.id)
      end)
    end)
    |> restart_zones(hosted_zones, max_zones)
  end

  defp get_member_zones(members) do
    members
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(fn controller ->
      {controller, ZoneController.hosted_zones(controller)}
    end)
  end

  defp restart_zones(zones, [], _max_zones) do
    raise "Something bad happened, ran out of nodes to place these zones #{inspect(zones)}"
  end

  defp restart_zones([], _controllers, _max_zones), do: :ok

  defp restart_zones(
         [zone | zones],
         [{controller, controller_zones} | controllers_with_zones],
         max_zones
       ) do
    case length(controller_zones) >= max_zones do
      true ->
        restart_zones([zone | zones], controllers_with_zones, max_zones)

      false ->
        Logger.info("Starting zone on #{inspect(controller)}")

        ZoneController.start_zone(controller, zone)

        controller_zones = [zone | controller_zones]
        restart_zones(zones, [{controller, controller_zones} | controllers_with_zones], max_zones)
    end
  end
end
