defmodule Test.Game.NPC do
  def greet(id, who) do
    send(self(), {:npc, :greet, {id, who}})
  end

  def notify(id, action) do
    send(self(), {:npc, :notify, {id, action}})
  end

  defmodule Helpers do
    defmacro assert_npc_greet() do
      quote do
        assert_received {:npc, :greet, _}
      end
    end

    defmacro assert_npc_notify(event) do
      quote do
        assert_received {:npc, :notify, unquote(event)}
      end
    end
  end
end
