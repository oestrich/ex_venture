defmodule Test.DoorHelper do
  alias Game.Door

  def start_and_clear_doors() do
    Door.start_link()
    Door.clear()
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
