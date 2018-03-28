defmodule Test.DamageTypesHelper do
  alias Game.DamageTypes

  def start_and_clear_damage_types() do
    DamageTypes.start_link()
    DamageTypes.clear()
  end

  def insert_damage_type(damage_type) do
    DamageTypes.insert(damage_type)
    ensure_process_caught_up(DamageTypes)
    damage_type
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
