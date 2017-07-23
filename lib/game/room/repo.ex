defmodule Game.Room.Repo do
  import Ecto.Query

  alias Data.Room
  alias Data.Repo

  @doc """
  Load all rooms
  """
  @spec all() :: [Room.t]
  def all() do
    Room
    |> preload([:room_items])
    |> Repo.all
  end

  def update(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update
  end
end
