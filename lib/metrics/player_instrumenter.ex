defmodule Metrics.PlayerInstrumenter do
  @moduledoc """
  Player metrics
  """

  use Prometheus.Metric

  require Logger

  def setup() do
    Gauge.declare(name: :exventure_player_count, help: "Number of players signed in currently")

    Counter.declare(
      name: :exventure_session_total,
      help: "Session process counter",
      labels: [:type]
    )

    Counter.declare(
      name: :exventure_session_recovery_total,
      help: "Count of recovered crashed sessions"
    )

    Counter.declare(name: :exventure_login_total, help: "Login counter")
    Counter.declare(name: :exventure_login_failure_total, help: "Login failure counter")
    Counter.declare(name: :exventure_new_character_total, help: "New character is created")
  end

  def session_started(type) do
    Counter.inc(name: :exventure_session_total, labels: [type])
  end

  def session_recovered() do
    Counter.inc(name: :exventure_session_recovery_total)
  end

  def login(user) do
    Logger.info("Player (#{user.id}) logged in #{inspect(self())}", type: :session)
    Counter.inc(name: :exventure_login_total)
  end

  def login_fail() do
    Counter.inc(name: :exventure_login_failure_total)
  end

  def new_character() do
    Counter.inc(name: :exventure_new_character_total)
  end

  @doc """
  Set the player count gauge, will return the player list
  """
  @spec set_player_count(list) :: list
  def set_player_count(players) do
    Gauge.set([name: :exventure_player_count], length(players))
    players
  end
end
