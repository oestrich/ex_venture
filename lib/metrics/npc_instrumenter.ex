defmodule Metrics.NPCInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  @doc false
  def setup() do
    Counter.declare(
      name: :exventure_npc_event_total,
      help: "Total count of NPC events",
      labels: [:type]
    )

    events = [
      [:exventure, :npc, :event, :acted]
    ]

    :telemetry.attach_many("exventure-npcs", events, &handle_event/4, nil)
  end

  def handle_event([:exventure, :npc, :event, :acted], _count, %{event: type}, _config) do
    Counter.inc(name: :exventure_npc_event_total, labels: [type])
  end
end
