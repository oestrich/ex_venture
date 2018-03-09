defmodule Metrics.CommunicationInstrumenter do
  @moduledoc """
  Communication metrics
  """

  use Prometheus.Metric

  require Logger

  def setup() do
    Counter.declare(name: :exventure_channel_broadcast_total, help: "Channel broadcast total", labels: [:channel])
    Counter.declare(name: :exventure_emote_total, help: "Room leve emote totals")
    Counter.declare(name: :exventure_say_total, help: "Room leve say totals")
  end

  def channel_broadcast(channel) do
    Counter.inc(name: :exventure_channel_broadcast_total, labels: [channel])
  end

  def emote() do
    Counter.inc(name: :exventure_emote_total)
  end

  def say() do
    Counter.inc(name: :exventure_say_total)
  end
end
