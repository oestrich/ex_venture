defmodule Data.Exit do
  @moduledoc """
  Exit Schema
  """

  use Data.Schema

  alias Data.Room

  schema "exits" do
    belongs_to :north, Room
    belongs_to :east, Room
    belongs_to :south, Room
    belongs_to :west, Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:north_id, :east_id, :south_id, :west_id])
    |> validate_direction()
    |> unique_constraint(:north_id)
    |> unique_constraint(:south_id)
    |> unique_constraint(:west_id)
    |> unique_constraint(:east_id)
  end

  defp validate_direction(changeset) do
    case changeset.changes |> Map.keys |> Enum.sort do
      [:north_id, :south_id] -> changeset
      [:east_id, :west_id] -> changeset
      _ ->
        add_error(changeset, :exits, "are invalid")
    end
  end

  @doc """
  Load all exits for a room

  Adds them to the room as `exits`
  """
  @spec load_exits(room :: Room.t) :: Room.t
  def load_exits(room, opts \\ []) do
    query = __MODULE__
    |> where([e], e.north_id == ^room.id)
    |> or_where([e], e.south_id == ^room.id)
    |> or_where([e], e.east_id == ^room.id)
    |> or_where([e], e.west_id == ^room.id)

    query = case Keyword.get(opts, :preload) do
      true -> query |> preload([:north, :south, :east, :west])
      _ -> query
    end

    %{room | exits: query |> Repo.all}
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
  """
  @spec opposite_id(direction :: String.t | atom) :: atom
  def opposite_id("north"), do: :south_id
  def opposite_id("east"), do: :west_id
  def opposite_id("south"), do: :north_id
  def opposite_id("west"), do: :east_id
  def opposite_id(:north), do: :south_id
  def opposite_id(:east), do: :west_id
  def opposite_id(:south), do: :north_id
  def opposite_id(:west), do: :east_id

  @doc """
  Get an exit in a direction
  """
  @spec exit_to(room :: Room.t, direction :: String.t | atom) :: Exit.t | nil
  def exit_to(room, direction) do
    Enum.find(room.exits, fn (room_exit) ->
      Map.get(room_exit, opposite_id(direction)) == room.id
    end)
  end
end
