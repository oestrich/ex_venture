defmodule Test.ChannelsHelper do
  alias Game.Channels

  def insert_channel(channel) do
    Channels.insert(channel)
    ensure_process_caught_up(Channels)
    channel
  end

  def ensure_process_caught_up(pid) do
    :sys.get_state(pid)
  end
end
