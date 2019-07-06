defmodule Game.Caches do
  @moduledoc """
  Game Cache Supervisor

  Supervise the Cachex caches
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    children = [
      worker(Cachex, [:channels, []], id: :channels_cache),
      worker(Cachex, [:color_codes, []], id: :color_code_cache),
      worker(Cachex, [:damage_types, []], id: :damage_type_cache),
      worker(Cachex, [:doors, []], id: :doors_cache),
      worker(Cachex, [:door_locks, []], id: :door_locks_cache),
      worker(Cachex, [:features, []], id: :features_cache),
      worker(Cachex, [:help_topics, []], id: :help_cache),
      worker(Cachex, [:items, []], id: :items_cache),
      worker(Cachex, [:npcs, []], id: :npcs_cache),
      worker(Cachex, [:proficiencies, []], id: :proficiencies_cache),
      worker(Cachex, [:rooms, []], id: :rooms_cache),
      worker(Cachex, [:skills, []], id: :skills_cache),
      worker(Cachex, [:socials, []], id: :socials_cache),
      worker(Cachex, [:zones, []], id: :zones_cache),
      worker(Game.Channels, []),
      worker(Game.ColorCodes, []),
      worker(Game.DamageTypes, []),
      worker(Game.Door, []),
      worker(Game.DoorLock, []),
      worker(Game.Features, []),
      worker(Game.Items, []),
      worker(Game.Proficiencies, []),
      worker(Game.Skills, []),
      worker(Game.Socials, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
