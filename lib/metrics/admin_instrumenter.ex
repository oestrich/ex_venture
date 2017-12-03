defmodule Metrics.AdminInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  require Logger

  def setup() do
    Counter.declare([name: :exventure_admin_npc_control_count, help: "Count of Admins controlling NPCs"])
    Counter.declare([name: :exventure_admin_npc_control_action_count, help: "Count of Admins speaking as an NPCs", labels: [:action]])
    Counter.declare([name: :exventure_admin_user_watch_count, help: "Count of Admins watching players"])
  end

  def watching_player() do
    Counter.inc([name: :exventure_admin_user_watch_count])
  end

  def control_npc() do
    Counter.inc([name: :exventure_admin_npc_control_count])
  end

  def action(action) do
    Counter.inc([name: :exventure_admin_npc_control_action_count, labels: [action]])
  end
end
