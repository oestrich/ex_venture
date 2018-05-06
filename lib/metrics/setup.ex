defmodule Metrics.Setup do
  @moduledoc """
  Common area to set up metrics
  """

  def setup() do
    Metrics.AdminInstrumenter.setup()
    Metrics.CharacterInstrumenter.setup()
    Metrics.CommandInstrumenter.setup()
    Metrics.CommunicationInstrumenter.setup()
    Metrics.PipelineInstrumenter.setup()
    Metrics.PlayerInstrumenter.setup()
    Metrics.NPCInstrumenter.setup()
    Metrics.RepoInstrumenter.setup()
    Metrics.ShopInstrumenter.setup()

    Web.PrometheusExporter.setup()
  end
end
