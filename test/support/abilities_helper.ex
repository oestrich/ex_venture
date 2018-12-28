defmodule Test.AbilitiesHelper do
  alias Game.Abilities

  def start_and_clear_abilities() do
    Abilities.start_link()
    Abilities.clear()
  end

  def insert_ability(ability) do
    Abilities.insert(ability)
    ensure_process_caught_up(Abilities)
    ability
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
