defmodule Game.Session.Registry do
  @registry_key "player"

  def register(user) do
    Registry.register(__MODULE__, @registry_key, user)
  end

  def unregister() do
    Registry.unregister(__MODULE__, @registry_key)
  end

  def connected_players() do
    __MODULE__
    |> Registry.lookup(@registry_key)
  end
end
