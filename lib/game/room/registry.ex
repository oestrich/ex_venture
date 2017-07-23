defmodule Game.Room.Registry do
  @registry_key "room"

  def register() do
    Registry.register(__MODULE__, @registry_key, :connected)
  end

  def unregister() do
    Registry.unregister(__MODULE__, @registry_key)
  end

  def connected_rooms() do
    __MODULE__
    |> Registry.lookup(@registry_key)
  end
end
