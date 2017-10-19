defmodule Metrics.PipelineInstrumenter do  
  @moduledoc """
  Pipeline Instrumenter for Plugs
  """

  use Prometheus.PlugPipelineInstrumenter

  def label_value(:request_path, conn) do
    conn.request_path
  end
end  
