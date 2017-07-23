defmodule Game.Room.Repo do
  alias Data.Room
  alias Data.Repo

  def update(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update
  end
end
