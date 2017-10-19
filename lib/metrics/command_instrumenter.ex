defmodule Metrics.CommandInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  def setup() do
    Counter.declare([name: :exventure_command_total, help: "Command Count", labels: [:command]])
  end

  def inc(command) do
    Counter.inc([name: :exventure_command_total, labels: [command]])
  end
end
