defmodule Game.Account do
  @moduledoc """
  Handle database interactions for a user
  """

  alias Data.Repo
  alias Data.Save
  alias Data.Stats
  alias Data.User
  alias Game.Config

  @doc """
  Create a new user from attributes
  """
  @spec create(attributes :: map, save_attributes :: map) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def create(attributes, %{race: race, class: class}) do
    save =
      Config.starting_save()
      |> Map.put(:stats, race.starting_stats() |> Stats.default())

    attributes = attributes
    |> Map.put(:race_id, race.id)
    |> Map.put(:class_id, class.id)
    |> Map.put(:save, save)

    case create_account(attributes) do
      {:ok, user} ->
        user = user
        |> Repo.preload([:race])
        |> Repo.preload([class: :skills])
        {:ok, user}
      anything -> anything
    end
  end

  defp create_account(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end

  @doc """
  Update the user's save
  """
  @spec save(User.t, Save.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def save(user, save) do
    user = %{user | save: %{}}
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end

  def update_time_online(user, session_started_at, now) do
    user
    |> User.changeset(%{seconds_online: current_play_time(user, session_started_at, now)})
    |> Repo.update
  end

  def current_play_time(user, session_started_at, now) do
    play_time = Timex.diff(now, session_started_at, :seconds)
    user.seconds_online + play_time
  end
end
