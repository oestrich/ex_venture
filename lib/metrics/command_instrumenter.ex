defmodule Metrics.CommandInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  require Logger

  def setup() do
    Counter.declare(name: :exventure_command_total, help: "Command Count", labels: [:command])

    Histogram.declare(
      name: :exventure_command_parsed_in_seconds,
      help: "Parse time for a command",
      buckets: [0.0001, 0.0002, 0.0003, 0.0004, 0.0005, 0.0006, 0.0007, 0.0008, 0.001],
      duration_unit: :seconds
    )

    Histogram.declare(
      name: :exventure_command_ran_in_seconds,
      help: "Run time for a command",
      buckets: :default,
      duration_unit: :seconds
    )

    Counter.declare(name: :exventure_command_bad_parse_total, help: "Bad command parse counts")
  end

  def command_run(session, command) do
    Logger.info(
      "Command for session #{inspect(session)} [text=\"#{command.text}\", module=#{command.module}, system=#{
        command.system
      }, continue=#{command.continue}, parsed_in=#{command.parsed_in}μs, ran_in=#{command.ran_in}μs]",
      type: :command
    )

    command_label =
      command.module
      |> to_string()
      |> String.split(".")
      |> List.last()

    Counter.inc(name: :exventure_command_total, labels: [command_label])
    record_timing(command)
  end

  defp record_timing(%{parsed_in: parsed_in, ran_in: ran_in})
       when parsed_in != nil and ran_in != nil do
    Histogram.observe([name: :exventure_command_parsed_in_seconds], parsed_in)
    Histogram.observe([name: :exventure_command_ran_in_seconds], ran_in)
  end

  defp record_timing(_), do: nil

  def bad_parse() do
    Counter.inc(name: :exventure_command_bad_parse_total)
  end
end
