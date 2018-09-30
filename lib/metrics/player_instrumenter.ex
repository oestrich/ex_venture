defmodule Metrics.PlayerInstrumenter do
  @moduledoc """
  Player metrics
  """

  use Prometheus.Metric

  require Logger

  def setup() do
    Gauge.declare(
      name: :exventure_player_count,
      help: "Number of players signed in currently",
      labels: [:role]
    )

    Gauge.declare(
      name: :exventure_player_random_character_name_pool_count,
      help: "Number of random character name's left in the pool to pick from"
    )

    Counter.declare(
      name: :exventure_session_total,
      help: "Session process counter",
      labels: [:type]
    )

    Counter.declare(
      name: :exventure_session_recovery_total,
      help: "Count of recovered crashed sessions"
    )

    Counter.declare(
      name: :exventure_player_start_password_reset_total,
      help: "Count of password resets started"
    )

    Counter.declare(
      name: :exventure_player_password_reset_total,
      help: "Count of password resets"
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

  def start_password_reset() do
    Counter.inc(name: :exventure_player_start_password_reset_total)
  end

  def password_reset() do
    Counter.inc(name: :exventure_player_password_reset_total)
  end

  @doc """
  Set the player count gauge, will return the player list
  """
  @spec set_player_count(map()) :: :ok
  def set_player_count(counts) do
    Gauge.set([name: :exventure_player_count, labels: [:players]], counts.player_count)
    Gauge.set([name: :exventure_player_count, labels: [:admins]], counts.admin_count)
  end

  @doc """
  Set the number of random names left in the character name pool
  """
  @spec set_random_character_name_count([String.t()]) :: :ok
  def set_random_character_name_count(names) do
    Gauge.set([name: :exventure_player_random_character_name_pool_count], length(names))
  end
end
