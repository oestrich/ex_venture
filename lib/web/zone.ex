defmodule Web.Zone do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Exit
  alias Data.Zone
  alias Data.Zone.MapCell
  alias Data.Room
  alias Data.Repo
  alias Game.Door
  alias Game.World
  alias Web.Pagination

  defdelegate types(), to: Zone

  def rooms?(zone) do
    zone.type == "rooms"
  end

  def overworld?(zone) do
    zone.type == "overworld"
  end

  @doc """
  Get all zones
  """
  @spec all(opts :: Keyword.t()) :: [Zone.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})
    query = Zone |> order_by([z], z.id)
    query |> Pagination.paginate(opts)
  end

  @doc """
  List out all zones for a select box
  """
  @spec zone_select() :: [{String.t(), integer()}]
  def zone_select() do
    Zone
    |> select([z], [z.name, z.id])
    |> order_by([z], z.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a zone

  Preload rooms
  """
  @spec get(id :: integer) :: [Zone.t()]
  def get(id) do
    Zone
    |> where([z], z.id == ^id)
    |> preload([:graveyard])
    |> preload(rooms: ^from(r in Room, order_by: r.id))
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Zone{} |> Zone.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(zone :: Zone.t()) :: changeset :: map
  def edit(zone), do: zone |> Zone.changeset(%{})

  @doc """
  Create a zone
  """
  @spec create(params :: map) :: {:ok, Zone.t()} | {:error, changeset :: map}
  def create(params) do
    changeset = %Zone{} |> Zone.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, zone} ->
        World.start_child(zone)
        {:ok, zone}

      anything ->
        anything
    end
  end

  @doc """
  Update an zone
  """
  @spec update(id :: integer, params :: map) :: {:ok, Zone.t()} | {:error, changeset :: map}
  def update(id, params) do
    zone = id |> get()
    changeset = zone |> Zone.changeset(params)

    case changeset |> Repo.update() do
      {:ok, zone} ->
        Game.Zone.update(zone.id, zone)
        {:ok, zone}

      anything ->
        anything
    end
  end

  @doc """
  Update an zone
  """
  @spec update_map(integer(), map()) :: {:ok, Zone.t()} | {:error, map()}
  def update_map(id, params) do
    zone = id |> get()
    changeset = zone |> Zone.map_changeset(cast_map_params(params))

    case changeset |> Repo.update() do
      {:ok, zone} ->
        Game.Zone.update(zone.id, zone)
        {:ok, zone}

      anything ->
        anything
    end
  end

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_map_params(map()) :: map()
  def cast_map_params(params) do
    params |> parse_map()
  end

  defp parse_map(params = %{"overworld_map" => overworld_map}) do
    case Poison.decode(overworld_map) do
      {:ok, overworld_map} ->
        overworld_map = cast_map(overworld_map)
        Map.put(params, "overworld_map", overworld_map)

      _ ->
        params
    end
  end

  defp cast_map(overworld_map) do
    overworld_map
    |> Enum.map(fn cell ->
      case MapCell.load(cell) do
        {:ok, cell} ->
          cell

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Helper for selecting room exits
  """
  def room_exits(zone) do
    Zone
    |> order_by([z], z.id)
    |> preload(rooms: ^rooms_query(zone))
    |> Repo.all()
    |> Enum.map(fn zone ->
      rooms = Enum.map(zone.rooms, &{"#{&1.id} - #{&1.name}", &1.id})
      {zone.name, rooms}
    end)
  end

  defp rooms_query(zone) do
    from(
      r in Room,
      order_by: r.id,
      where: r.is_zone_exit == true,
      or_where: r.zone_id == ^zone.id
    )
  end

  @doc """
  Helper for selecting a zone graveyard
  """
  def graveyards() do
    Zone
    |> order_by([z], z.id)
    |> preload(rooms: ^from(r in Room, order_by: r.id, where: r.is_graveyard == true))
    |> Repo.all()
    |> Enum.map(fn zone ->
      rooms = Enum.map(zone.rooms, &{"#{&1.id} - #{&1.name}", &1.id})
      {zone.name, rooms}
    end)
  end

  def modify_overworld_exits(zone, exits_to_add, exits_to_delete) do
    with {:ok, zone} <- check_overworld(zone),
         :ok <- add_exits(zone, exits_to_add),
         :ok <- delete_exits(exits_to_delete),
         {:ok, zone} <- load_exits(zone) do
      {:ok, zone}
    end
  end

  defp check_overworld(zone) do
    case zone.type do
      "overworld" ->
        {:ok, zone}

      _ ->
        {:error, :not_overworld}
    end
  end

  defp add_exits(zone, exits_to_add) do
    Enum.map(exits_to_add, &add_exit(zone, &1))
    :ok
  end

  defp add_exit(zone, room_exit) do
    room_exit = Map.put(room_exit, "start_zone_id", zone.id)
    case Web.Exit.create_exit(room_exit) do
      {:ok, room_exit, reverse_exit} ->
        room_exit |> Web.Exit.reload_process() |> Door.maybe_load()
        reverse_exit |> Web.Exit.reload_process() |> Door.maybe_load()

        :ok
    end
  end

  defp delete_exits(exits_to_delete) do
    Enum.map(exits_to_delete, &delete_exit/1)

    :ok
  end

  def delete_exit(room_exit_id) do
    case Web.Exit.delete_exit(room_exit_id) do
      {:ok, _room_exit, reverse_exit} ->
        reverse_exit |> Web.Exit.reload_process() |> Door.remove()

        :ok
    end
  end

  defp load_exits(zone) do
    {:ok, zone |> Exit.load_zone_exits()}
  end
end
