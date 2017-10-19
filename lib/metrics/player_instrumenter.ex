defmodule Metrics.PlayerInstrumenter do
  @moduledoc """
  Player metrics
  """

  use Prometheus.Metric

  def setup() do
    Gauge.declare([name: :exventure_player_count, help: "Number of players signed in currently"])
  end

  def set_player_count(players) do
    Gauge.set([name: :exventure_player_count], length(players))
    players
  end
end
