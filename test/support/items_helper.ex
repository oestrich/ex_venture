defmodule Test.ItemsHelper do
  alias Game.Items

  def start_and_clear_items() do
    Items.start_link
    Items.clear
  end

  def insert_item(item) do
    Items.insert(item)
    ensure_process_caught_up(Items)
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
