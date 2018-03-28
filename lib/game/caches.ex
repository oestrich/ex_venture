defmodule Game.Caches do
  @moduledoc """
  Game Cache Supervisor

  Supervise the Cachex caches
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Cachex, [:channels, []], id: :channels_cache),
      worker(Cachex, [:damage_types, []], id: :damage_type_cache),
      worker(Cachex, [:doors, []], id: :doors_cache),
      worker(Cachex, [:items, []], id: :items_cache),
      worker(Cachex, [:skills, []], id: :skills_cache),
      worker(Cachex, [:socials, []], id: :socials_cache)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
