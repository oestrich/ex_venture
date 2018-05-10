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
      name: :exventure_character_moved_in_microseconds,
      help: "Parse time for a command",
      buckets: [10, 35, 80, 100, 135, 170, 200, 250, 300, 400],
      duration_unit: :microseconds
    )
  end

  def movement(type, fun) do
    start_time = Timex.now()

    movement = fun.()

    moved_in =
      Timex.now()
      |> Timex.diff(start_time, :microseconds)
      |> :erlang.convert_time_unit(:microsecond, :native)

    Counter.inc(name: :exventure_character_movement_total, labels: [type])
    Histogram.dobserve(:exventure_character_moved_in_microseconds, moved_in)

    movement
  end
end
