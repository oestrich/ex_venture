defmodule Test.Game.Shop do
  alias Data.Item
  alias Data.Shop

  def start_link() do
    Agent.start_link(fn () -> %{shop: _shop()} end, name: __MODULE__)
  end

  def _shop() do
    %Shop{
      name: "Tree Stand Shop",
    }
  end

  def set_shop(shop) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :shop, shop) end)
  end

  def list(_id) do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :shop) end)
  end

  def set_buy(buy_response) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :buy_response, buy_response) end)
  end

  def buy(id, item_id, save) do
    start_link()
    Agent.get_and_update(__MODULE__, fn (state) ->
      buys = Map.get(state, :buy, [])
      state = Map.put(state, :buy, buys ++ [{id, item_id, save}])
      response = Map.get(state, :buy_response, {:ok, %{save | currency: save.currency - 1}, %Item{}})
      {response, state}
    end)
  end

  def get_buys() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :buy, []) end)
  end

  def clear_buys() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :buy, []) end)
  end
end
