defmodule Test.SkillsHelper do
  alias Game.Skills

  def start_and_clear_skills() do
    Skills.start_link()
    Skills.clear()
  end

  def insert_skill(skill) do
    Skills.insert(skill)
    ensure_process_caught_up(Skills)
    skill
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
