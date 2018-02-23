defmodule Web.Channel do
  @moduledoc """
  Context Module for talking to the in game channels
  """

  import Ecto.Query

  alias Data.Channel
  alias Data.Repo
  alias Game.Channels

  @doc """
  Get all channels active in the game
  """
  def all() do
    Channel
    |> order_by([c], c.name)
    |> Repo.all()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: map()
  def new(), do: %Channel{} |> Channel.changeset(%{})

  @doc """
  Create a class
  """
  @spec create(map) :: {:ok, Class.t()} | {:error, map}
  def create(params) do
    changeset = %Channel{} |> Channel.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, channel} ->
        Channels.insert(channel)
        {:ok, channel}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
