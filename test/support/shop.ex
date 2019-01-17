defmodule Test.Game.Shop do
  alias Data.Shop
  alias Test.Game.Shop.FakeShop

  def set_shop(shop) do
    {:ok, pid} = FakeShop.start_link(shop)
    Process.put({:shop, shop.id}, pid)
  end

  def list(id) do
    GenServer.call(Process.get({:shop, id}), {:list})
  end

  def set_buy(shop, response) do
    GenServer.call(Process.get({:shop, shop.id}), {:put, {:buy, response}})
  end

  def buy(id, item_id, save) do
    GenServer.call(Process.get({:shop, id}), {:buy, item_id, save})
  end

  def set_sell(shop, response) do
    GenServer.call(Process.get({:shop, shop.id}), {:put, {:sell, response}})
  end

  def sell(id, item_name, save) do
    GenServer.call(Process.get({:shop, id}), {:sell, item_name, save})
  end

  defmodule FakeShop do
    use GenServer

    def start_link(shop) do
      GenServer.start_link(__MODULE__, [shop: shop, caller: self()])
    end

    @impl true
    def init(opts) do
      state = %{
        shop: opts[:shop],
        caller: opts[:caller],
        responses: %{}
      }

      {:ok, state}
    end

    @impl true
    def handle_call({:put, {field, response}}, _from, state) do
      responses = Map.put(state.responses, field, response)
      state = Map.put(state, :responses, responses)

      {:reply, :ok, state}
    end

    def handle_call({:list}, _from, state) do
      {:reply, state.shop, state}
    end

    def handle_call({:buy, item_id, save}, _from, state) do
      send(state.caller, {:buy, {state.shop.id, item_id, save}})

      {:reply, state.responses[:buy], state}
    end

    def handle_call({:sell, item_name, save}, _from, state) do
      send(state.caller, {:sell, {state.shop.id, item_name, save}})

      {:reply, state.responses[:sell], state}
    end
  end

  defmodule Helpers do
    alias Test.Game.Shop

    def start_shop(shop) do
      Shop.set_shop(shop)
    end

    def put_shop_buy_response(shop, response) do
      Shop.set_buy(shop, response)
    end

    def put_shop_sell_response(shop, response) do
      Shop.set_sell(shop, response)
    end

    defmacro assert_shop_buy(message) do
      quote do
        assert_received {:buy, unquote(message)}
      end
    end

    defmacro assert_shop_sell(message) do
      quote do
        assert_received {:sell, unquote(message)}
      end
    end
  end
end
