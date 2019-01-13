defmodule Test.HelpHelper do
  alias Game.Help.Agent, as: HelpAgent

  def start_and_clear_help() do
    HelpAgent.clear()
  end

  def insert_help_topic(topic) do
    HelpAgent.insert(topic)
    ensure_process_caught_up(HelpAgent)
    topic
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
