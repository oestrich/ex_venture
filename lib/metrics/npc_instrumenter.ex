defmodule Metrics.NPCInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  def setup() do
    Counter.declare(
      name: :exventure_npc_event_total,
      help: "Total count of NPC events",
      labels: [:type]
    )

    Counter.declare(
      name: :exventure_npc_tick_event_total,
      help: "Total count of NPC tick events",
      labels: [:type]
    )
  end

  def event_acted_on(type) do
    Counter.inc(name: :exventure_npc_event_total, labels: [type])
  end

  def tick_event_acted_on(type) do
    Counter.inc(name: :exventure_npc_event_total, labels: [type])
  end
end
