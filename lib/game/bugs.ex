defmodule Game.Bugs do
  @moduledoc """
  Game context for bugs, repo like
  """

  import Ecto.Query

  alias Data.Bug
  alias Data.Repo

  @doc """
  Get a list of bugs that a player submitted
  """
  @spec reported_by(Character.t()) :: [Bug.t()]
  def reported_by(character) do
    Bug
    |> where([b], b.reporter_id == ^character.id)
    |> order_by([b], asc: b.is_completed)
    |> Repo.all()
  end

  @doc """
  Get a bug scoped by the player
  """
  @spec get(Character.t(), integer()) :: {:ok, Bug.t()} | {:error, :not_found}
  def get(character, id) do
    bug =
      Bug
      |> where([b], b.reporter_id == ^character.id)
      |> where([b], b.id == ^id)
      |> Repo.one()

    case bug do
      nil ->
        {:error, :not_found}

      bug ->
        {:ok, bug}
    end
  end
end
