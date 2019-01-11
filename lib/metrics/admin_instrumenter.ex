defmodule Metrics.AdminInstrumenter do
  @moduledoc """
  Command metrics
  """

  use Prometheus.Metric

  require Logger

  @doc false
  def setup() do
    Counter.declare(
      name: :exventure_admin_npc_control_count,
      help: "Count of Admins controlling NPCs"
    )

    Counter.declare(
      name: :exventure_admin_npc_control_action_count,
      help: "Count of Admins speaking as an NPCs",
      labels: [:action]
    )

    Counter.declare(
      name: :exventure_admin_user_watch_count,
      help: "Count of Admins watching players"
    )

    events = [
      [:exventure, :admin, :npc, :control],
      [:exventure, :admin, :npc, :control, :action],
      [:exventure, :admin, :user, :watch],
    ]

    :telemetry.attach_many("exventure-admin", events, &handle_event/4, nil)
  end

  def handle_event([:exventure, :admin, :npc, :control], _count, _metadata, _config) do
    Counter.inc(name: :exventure_admin_npc_control_count)
  end

  def handle_event([:exventure, :admin, :npc, :control, :action], _count, %{action: action}, _config) do
    Counter.inc(name: :exventure_admin_npc_control_action_count, labels: [action])
  end

  def handle_event([:exventure, :admin, :user, :watch], _count, _metadata, _config) do
    Counter.inc(name: :exventure_admin_user_watch_count)
  end
end
