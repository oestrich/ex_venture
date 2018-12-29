defmodule Test.ProficienciesHelper do
  alias Game.Proficiencies

  def start_and_clear_proficiencies() do
    Proficiencies.start_link()
    Proficiencies.clear()
  end

  def insert_proficiency(proficiency) do
    Proficiencies.insert(proficiency)
    ensure_process_caught_up(Proficiencies)
    proficiency
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
