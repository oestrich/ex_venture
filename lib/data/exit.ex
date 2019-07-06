defmodule Data.Exit do
  @moduledoc """
  Exit Schema
  """

  use Data.Schema

  alias Data.Proficiency
  alias Data.Item
  alias Data.Room
  alias Data.Zone

  @directions [
    "north",
    "east",
    "south",
    "west",
    "up",
    "down",
    "in",
    "out",
    "north west",
    "north east",
    "south west",
    "south east"
  ]

  schema "exits" do
    field(:direction, :string)
    field(:has_door, :boolean, default: false)
    field(:door_id, Ecto.UUID)
    field(:has_lock, :boolean, default: false)

    field(:start_id, :string, virtual: true)
    field(:finish_id, :string, virtual: true)

    field(:start_overworld_id, :string)
    field(:finish_overworld_id, :string)

    embeds_many(:requirements, Proficiency.Requirement)

    belongs_to(:start_room, Room)
    belongs_to(:start_zone, Zone)

    belongs_to(:finish_room, Room)
    belongs_to(:finish_zone, Zone)

    belongs_to(:lock_key, Item)

    timestamps()
  end

  @doc """
  Get a list of directions
  """
  @spec directions() :: [String.t()]
  def directions(), do: @directions

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :direction,
      :has_door,
      :door_id,
      :has_lock,
      :lock_key_id,
      :start_room_id,
      :finish_room_id,
      :start_overworld_id,
      :finish_overworld_id
    ])
    |> cast(params, [:start_zone_id, :finish_zone_id])
    |> cast_embed(:requirements, with: &Proficiency.Requirement.changeset/2)
    |> validate_required([:direction, :has_door])
    |> validate_inclusion(:direction, @directions)
    |> validate_one_of([:start_room_id, :start_overworld_id])
    |> validate_one_of([:finish_room_id, :finish_overworld_id])
    |> validate_proficiencies()
    |> foreign_key_constraint(:start_room_id)
    |> foreign_key_constraint(:finish_room_id)
    |> unique_constraint(:start_room_id, name: :exits_direction_start_room_id_index)
    |> unique_constraint(:start_overworld_id, name: :exits_direction_start_overworld_id_index)
    |> unique_constraint(:finish_room_id, name: :exits_direction_finish_room_id_index)
    |> unique_constraint(:finish_overworld_id, name: :exits_direction_finish_overworld_id_index)
  end

  defp validate_one_of(changeset, keys) do
    keys =
      Enum.map(keys, fn key ->
        {key, get_field(changeset, key)}
      end)

    keys_with_values = Enum.filter(keys, fn {_key, value} -> !is_nil(value) end)

    case length(keys_with_values) == 1 do
      true ->
        changeset

      false ->
        Enum.reduce(keys, changeset, fn {key, _value}, changeset ->
          add_error(changeset, key, "cannot be combined with other values")
        end)
    end
  end

  def validate_proficiencies(changeset) do
    case get_change(changeset, :requirements) do
      nil ->
        changeset

      requirements ->
        case Enum.all?(requirements, &(&1.valid?)) do
          true ->
            changeset

          false ->
            add_error(changeset, :requirements, "are invalid")
        end
    end
  end

  @doc """
  Load all exits for a room

  Adds them to the room as `exits`
  """
  @spec load_exits(Room.t()) :: Room.t()
  def load_exits(room, opts \\ []) do
    query = where(__MODULE__, [e], e.start_room_id == ^room.id)

    query =
      case Keyword.get(opts, :preload) do
        true ->
          query |> preload([:start_room, :finish_room, :start_zone, :finish_zone])

        _ ->
          query
      end

    exits =
      query
      |> Repo.all()
      |> Enum.map(&setup_exit/1)

    %{room | exits: exits}
  end

  @doc """
  Load all exits for a zone

  Adds them to the zone as `exits`
  """
  @spec load_zone_exits(Zone.t()) :: Zone.t()
  def load_zone_exits(zone) do
    exits =
      __MODULE__
      |> where([e], e.start_zone_id == ^zone.id)
      |> Repo.all()
      |> Enum.map(&setup_exit/1)

    %{zone | exits: exits}
  end

  @doc """
  Sets up exits for the overworld

      iex> room_exit = Data.Exit.setup_exit(%{start_room_id: 1, finish_room_id: 1})
      iex> %{start_id: 1, finish_id: 1} == Map.take(room_exit, [:start_id, :finish_id])
      true

      iex> room_exit = Data.Exit.setup_exit(%{start_overworld_id: "overworld", finish_room_id: 1})
      iex> %{start_id: "overworld", finish_id: 1} == Map.take(room_exit, [:start_id, :finish_id])
      true

      iex> room_exit = Data.Exit.setup_exit(%{start_room_id: 1, finish_overworld_id: "overworld"})
      iex> %{start_id: 1, finish_id: "overworld"} == Map.take(room_exit, [:start_id, :finish_id])
      true

      iex> room_exit = Data.Exit.setup_exit(%{start_overworld_id: "overworld", finish_overworld_id: "overworld"})
      iex> %{start_id: "overworld", finish_id: "overworld"} == Map.take(room_exit, [:start_id, :finish_id])
      true
  """
  def setup_exit(room_exit) do
    room_exit
    |> fallthrough(:start_id, :start_room_id, :start_overworld_id)
    |> fallthrough(:finish_id, :finish_room_id, :finish_overworld_id)
  end

  defp fallthrough(struct, field, base_field, fallthrough_field) do
    case Map.get(struct, base_field) do
      nil ->
        Map.put(struct, field, Map.get(struct, fallthrough_field))

      value ->
        Map.put(struct, field, value)
    end
  end

  @doc """
  Check if a string is a valid exit

      iex> Data.Exit.exit?("north")
      true

      iex> Data.Exit.exit?("outside")
      false
  """
  @spec exit?(String.t()) :: boolean()
  def exit?(direction), do: direction in @directions

  @doc """
  From a direction find the opposite direction's id

      iex> Data.Exit.opposite("north")
      "south"

      iex> Data.Exit.opposite("east")
      "west"

      iex> Data.Exit.opposite("south")
      "north"

      iex> Data.Exit.opposite("west")
      "east"

      iex> Data.Exit.opposite("up")
      "down"

      iex> Data.Exit.opposite("down")
      "up"

      iex> Data.Exit.opposite("in")
      "out"

      iex> Data.Exit.opposite("out")
      "in"

      iex> Data.Exit.opposite("north west")
      "south east"

      iex> Data.Exit.opposite("north east")
      "south west"

      iex> Data.Exit.opposite("south west")
      "north east"

      iex> Data.Exit.opposite("south east")
      "north west"
  """
  @spec opposite(String.t() | atom) :: atom
  def opposite("north"), do: "south"
  def opposite("east"), do: "west"
  def opposite("south"), do: "north"
  def opposite("west"), do: "east"
  def opposite("up"), do: "down"
  def opposite("down"), do: "up"
  def opposite("in"), do: "out"
  def opposite("out"), do: "in"
  def opposite("north west"), do: "south east"
  def opposite("north east"), do: "south west"
  def opposite("south west"), do: "north east"
  def opposite("south east"), do: "north west"

  @doc """
  Get an exit in a direction
  """
  @spec exit_to(Room.t(), String.t() | atom) :: Exit.t() | nil
  def exit_to(room, direction) do
    Enum.find(room.exits, &(&1.direction == direction))
  end
end
