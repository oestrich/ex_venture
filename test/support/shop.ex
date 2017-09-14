defmodule Test.Game.Shop do
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

  def list(id) do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :shop) end)
  end
end
