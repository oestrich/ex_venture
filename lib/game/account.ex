defmodule Game.Account do
  alias Data.Repo
  alias Data.User

  def create(attributes) do
    attributes = attributes
    |> Map.put(:save, starting_save())

    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end

  defp starting_save() do
    case Game.Room.starting() do
      nil -> %Data.Save{}
      room ->
        %Data.Save{
          room_id: room.id,
        }
    end
  end

  def save(user, save) do
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end
end
