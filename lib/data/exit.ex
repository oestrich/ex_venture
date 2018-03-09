defmodule Data.Exit do
  @moduledoc """
  Exit Schema
  """

  use Data.Schema

  alias Data.Room

  schema "exits" do
    field(:has_door, :boolean, default: false)

    belongs_to(:north, Room)
    belongs_to(:east, Room)
    belongs_to(:south, Room)
    belongs_to(:west, Room)
    belongs_to(:up, Room)
    belongs_to(:down, Room)
    belongs_to(:in, Room)
    belongs_to(:out, Room)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:has_door, :north_id, :east_id, :south_id, :west_id, :up_id, :down_id, :in_id, :out_id])
    |> validate_required([:has_door])
    |> validate_direction()
    |> foreign_key_constraint(:north_id)
    |> foreign_key_constraint(:south_id)
    |> foreign_key_constraint(:west_id)
    |> foreign_key_constraint(:east_id)
    |> foreign_key_constraint(:up_id)
    |> foreign_key_constraint(:down_id)
    |> foreign_key_constraint(:in_id)
    |> foreign_key_constraint(:out_id)
    |> unique_constraint(:north_id)
    |> unique_constraint(:south_id)
    |> unique_constraint(:west_id)
    |> unique_constraint(:east_id)
    |> unique_constraint(:down_id)
    |> unique_constraint(:up_id)
    |> unique_constraint(:in_id)
    |> unique_constraint(:out_id)
  end

  defp validate_direction(changeset) do
    case changeset.changes |> Map.keys() |> Enum.sort() |> List.delete(:has_door) do
      [:north_id, :south_id] ->
        changeset

      [:east_id, :west_id] ->
        changeset

      [:down_id, :up_id] ->
        changeset

      [:in_id, :out_id] ->
        changeset

      _ ->
        add_error(changeset, :exits, "are invalid")
    end
  end

  @doc """
  Load all exits for a room

  Adds them to the room as `exits`
  """
  @spec load_exits(Room.t()) :: Room.t()
  def load_exits(room, opts \\ []) do
    query =
      __MODULE__
      |> where([e], e.north_id == ^room.id)
      |> or_where([e], e.south_id == ^room.id)
      |> or_where([e], e.east_id == ^room.id)
      |> or_where([e], e.west_id == ^room.id)
      |> or_where([e], e.up_id == ^room.id)
      |> or_where([e], e.down_id == ^room.id)
      |> or_where([e], e.in_id == ^room.id)
      |> or_where([e], e.out_id == ^room.id)

    query =
      case Keyword.get(opts, :preload) do
        true -> query |> preload([:north, :south, :east, :west, :up, :down, :in, :out])
        _ -> query
      end

    %{room | exits: query |> Repo.all()}
  end

  @doc """
  From a direction find the opposite direction's id

      iex> Data.Exit.opposite_id("north")
      :south_id
      iex> Data.Exit.opposite_id(:north)
      :south_id

      iex> Data.Exit.opposite_id("east")
      :west_id
      iex> Data.Exit.opposite_id(:east)
      :west_id

      iex> Data.Exit.opposite_id("south")
      :north_id
      iex> Data.Exit.opposite_id(:south)
      :north_id

      iex> Data.Exit.opposite_id("west")
      :east_id
      iex> Data.Exit.opposite_id(:west)
      :east_id

      iex> Data.Exit.opposite_id("up")
      :down_id
      iex> Data.Exit.opposite_id(:up)
      :down_id

      iex> Data.Exit.opposite_id("down")
      :up_id
      iex> Data.Exit.opposite_id(:down)
      :up_id

      iex> Data.Exit.opposite_id("in")
      :out_id
      iex> Data.Exit.opposite_id(:in)
      :out_id

      iex> Data.Exit.opposite_id("out")
      :in_id
      iex> Data.Exit.opposite_id(:out)
      :in_id
  """
  @spec opposite_id(String.t() | atom) :: atom
  def opposite_id("north"), do: :south_id
  def opposite_id("east"), do: :west_id
  def opposite_id("south"), do: :north_id
  def opposite_id("west"), do: :east_id
  def opposite_id("up"), do: :down_id
  def opposite_id("down"), do: :up_id
  def opposite_id("in"), do: :out_id
  def opposite_id("out"), do: :in_id
  def opposite_id(:north), do: :south_id
  def opposite_id(:east), do: :west_id
  def opposite_id(:south), do: :north_id
  def opposite_id(:west), do: :east_id
  def opposite_id(:up), do: :down_id
  def opposite_id(:down), do: :up_id
  def opposite_id(:in), do: :out_id
  def opposite_id(:out), do: :in_id

  @doc """
  From a direction find the opposite direction's id

      iex> Data.Exit.opposite("north")
      :south
      iex> Data.Exit.opposite(:north)
      :south

      iex> Data.Exit.opposite("east")
      :west
      iex> Data.Exit.opposite(:east)
      :west

      iex> Data.Exit.opposite("south")
      :north
      iex> Data.Exit.opposite(:south)
      :north

      iex> Data.Exit.opposite("west")
      :east
      iex> Data.Exit.opposite(:west)
      :east

      iex> Data.Exit.opposite("up")
      :down
      iex> Data.Exit.opposite(:up)
      :down

      iex> Data.Exit.opposite("down")
      :up
      iex> Data.Exit.opposite(:down)
      :up

      iex> Data.Exit.opposite("in")
      :out
      iex> Data.Exit.opposite(:in)
      :out

      iex> Data.Exit.opposite("out")
      :in
      iex> Data.Exit.opposite(:out)
      :in
  """
  @spec opposite(String.t() | atom) :: atom
  def opposite("north"), do: :south
  def opposite("east"), do: :west
  def opposite("south"), do: :north
  def opposite("west"), do: :east
  def opposite("up"), do: :down
  def opposite("down"), do: :up
  def opposite("in"), do: :out
  def opposite("out"), do: :in
  def opposite(:north), do: :south
  def opposite(:east), do: :west
  def opposite(:south), do: :north
  def opposite(:west), do: :east
  def opposite(:up), do: :down
  def opposite(:down), do: :up
  def opposite(:in), do: :out
  def opposite(:out), do: :in

  @doc """
  Get an exit in a direction
  """
  @spec exit_to(Room.t(), String.t() | atom) :: Exit.t() | nil
  def exit_to(room, direction) do
    Enum.find(room.exits, fn room_exit ->
      Map.get(room_exit, opposite_id(direction)) == room.id
    end)
  end
end
