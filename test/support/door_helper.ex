defmodule Test.DoorHelper do
  alias Game.Door
  alias Game.DoorLock

  def start_and_clear_doors() do
    Door.start_link()
    DoorLock.start_link()
    Door.clear()
    DoorLock.clear()
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
