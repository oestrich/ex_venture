defmodule Metrics.ShopInstrumenter do
  @moduledoc """
  Shop metrics
  """

  use Prometheus.Metric

  def setup() do
    Counter.declare(name: :exventure_shops_buy_total, help: "Total buy price")
    Counter.declare(name: :exventure_shops_buy_count, help: "Total number of buys")
    Counter.declare(name: :exventure_shops_sell_total, help: "Total sell price")
    Counter.declare(name: :exventure_shops_sell_count, help: "Total number of sells")
  end

  def buy(amount) do
    Counter.inc([name: :exventure_shops_buy_total], amount)
    Counter.inc(name: :exventure_shops_buy_count)
  end

  def sell(amount) do
    Counter.inc([name: :exventure_shops_sell_total], amount)
    Counter.inc(name: :exventure_shops_sell_count)
  end
end
