defmodule Game.Session.Registry do
  @moduledoc """
  Helper functions for the connected users registry
  """

  @registry_key "player"

  alias Data.User

  @doc """
  Register the session PID for the user
  """
  @spec register(user :: User.t) :: :ok
  def register(user) do
    Registry.register(__MODULE__, @registry_key, user)
  end

  @doc """
  Unregister the current session pid
  """
  @spec unregister() :: :ok
  def unregister() do
    Registry.unregister(__MODULE__, @registry_key)
  end

  @doc """
  Load all connected players
  """
  @spec connected_players() :: [{pid, User.t}]
  def connected_players() do
    __MODULE__
    |> Registry.lookup(@registry_key)
  end
end
