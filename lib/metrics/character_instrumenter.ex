defmodule Metrics.CharacterInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  def setup() do
    Counter.declare(
      name: :exventure_character_movement_total,
      help: "Total count of character movements",
      labels: [:type]
    )

    Histogram.declare(
      name: :exventure_character_moved_in_seconds,
      help: "Parse time for a command",
      buckets: [
        0.000001,
        0.000035,
        0.00008,
        0.0001,
        0.000135,
        0.00017,
        0.0002,
        0.00025,
        0.0003,
        0.0004,
        0.001,
        0.005,
        0.01,
        0.025,
        0.1
      ],
      duration_unit: :seconds
    )
  end

  def movement(type, fun) do
    start_time = System.monotonic_time()
    movement = fun.()
    moved_in = System.monotonic_time() - start_time

    Counter.inc(name: :exventure_character_movement_total, labels: [type])
    Histogram.observe([name: :exventure_character_moved_in_seconds], moved_in)

    movement
  end
end
