defmodule Metrics.CharacterInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  def setup() do
    Counter.declare(name: :exventure_character_movement_total, help: "Total count of character movements", labels: [:type])
  end

  def movement(type) do
    Counter.inc(name: :exventure_character_movement_total, labels: [type])
  end
end
