defmodule Web.User do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.User
  alias Data.Repo
  alias Game.Authentication
  alias Game.Session
  alias Game.Session.Registry, as: SessionRegistry
  alias Web.Pagination

  @doc """
  Fetch a user from a web token
  """
  @spec from_token(token :: String.t) :: User.t
  def from_token(token) do
    User
    |> where([u], u.token == ^token)
    |> Repo.one
  end

  @doc """
  Load all users
  """
  @spec all(opts :: Keyword.t) :: [User.t]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})
    query = User |> order_by([u], desc: u.updated_at)
    query |> Pagination.paginate(opts)
  end

  @doc """
  Load a user
  """
  @spec get(id :: integer) :: User.t
  def get(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:class, :race])
  end

  @doc """
  List out connected players
  """
  @spec connected_players() :: [User.t]
  def connected_players() do
    SessionRegistry.connected_players()
    |> Enum.map(&(elem(&1, 1)))
  end

  @doc """
  Teleport a user to the room

  Updates the save and sends a message to their session
  """
  @spec teleport(user :: User.t, room_id :: integer) :: {:ok, User.t} | {:error, map}
  def teleport(user, room_id) do
    room_id = String.to_integer(room_id)
    save = %{user.save | room_id: room_id}
    changeset = user |> User.changeset(%{save: save})
    case changeset |> Repo.update() do
      {:ok, user} ->
        teleport_player_in_game(user, room_id)

        {:ok, user}
      anything -> anything
    end
  end

  def teleport_player_in_game(user, room_id) do
    player = SessionRegistry.connected_players()
    |> Enum.find(fn ({_, player}) -> player.id == user.id end)

    case player do
      nil -> nil
      {pid, _} -> pid |> Session.teleport(room_id)
    end
  end

  @doc """
  Change a user's password
  """
  @spec change_password(user :: User.t, current_password :: String.t, params :: map) :: {:ok, User.t}
  def change_password(user, current_password, params) do
    case Authentication.find_and_validate(user.name, current_password) do
      {:error, :invalid} -> {:error, :invalid}
      user ->
        user
        |> User.password_changeset(params)
        |> Repo.update
    end
  end
end
