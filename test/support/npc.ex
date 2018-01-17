defmodule Test.Game.NPC do
  alias Data.NPC

  def start_link() do
    Agent.start_link(fn () -> %{npc: _npc()} end, name: __MODULE__)
  end

  def _npc() do
    %NPC{
      id: 1,
      name: "Guard",
      level: 1,
      experience_points: 124,
      currency: 0,
      events: [],
      status_line: "{name} is here.",
      description: "{status_line}",
    }
  end

  def greet(id, who) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      greets = Map.get(state, :greet, [])
      Map.put(state, :greet, greets ++ [{id, who}])
    end)
  end

  def get_greets() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :greet, []) end)
  end

  def clear_greets() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :greet, []) end)
  end

  def notify(id, action) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      notifys = Map.get(state, :notify, [])
      Map.put(state, :notify, notifys ++ [{id, action}])
    end)
  end

  def get_notifies() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :notify, []) end)
  end

  def clear_notifies() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :notify, []) end)
  end
end
