defmodule Test.SocialsHelper do
  alias Game.Socials

  def start_and_clear_socials() do
    Socials.start_link()
    Socials.clear()
  end

  def insert_social(social) do
    Socials.insert(social)
    ensure_process_caught_up(Socials)
    social
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
