defmodule Game.Account do
  @moduledoc """
  Handle database interactions for a user's account.
  """

  alias Data.Repo
  alias Data.Save
  alias Data.Stats
  alias Data.User
  alias Data.User.Session
  alias Game.Config

  @doc """
  Create a new user from attributes. Preloads everything required to start playing the game.
  """
  @spec create(map, map) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
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
  Save the final session data for a play
  """
  @spec save_session(User.t(), Save.t(), Timex.t(), Timex.t()) :: {:ok, User.t()}
  def save_session(user, save, session_started_at, now) do
    case user |> save(save) do
      {:ok, user} ->
        user |> update_time_online(session_started_at, now)
        user |> create_session(session_started_at, now)

        {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Update the user's save data.
  """
  @spec save(User.t, Save.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def save(user, save) do
    user = %{user | save: %{}}
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end

  @doc """
  Update the seconds the player has been online.
  """
  @spec update_time_online(User.t, Timex.t, Timex.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def update_time_online(user, session_started_at, now) do
    user
    |> User.changeset(%{seconds_online: current_play_time(user, session_started_at, now)})
    |> Repo.update()
  end

  @doc """
  Calculate the current play time, old + current session.
  """
  @spec current_play_time(User.t, DateTime.t, DateTime.t) :: integer()
  def current_play_time(user, session_started_at, now) do
    play_time = Timex.diff(now, session_started_at, :seconds)
    user.seconds_online + play_time
  end

  def create_session(user, session_started_at, now) do
    play_time = Timex.diff(now, session_started_at, :seconds)
    user
    |> Ecto.build_assoc(:sessions)
    |> Session.changeset(%{started_at: session_started_at, seconds_online: play_time})
    |> Repo.insert
  end
end
