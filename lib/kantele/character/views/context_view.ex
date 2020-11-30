defmodule Kantele.Character.ContextView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.Event

  def render("item", %{context: context, item_instance: item_instance, verbs: verbs}) do
    %Event{
      topic: "Context.Verbs",
      data: %{
        context: context,
        type: "item",
        id: item_instance.id,
        verbs: verbs
      }
    }
  end

  def render("unknown", %{context: context, id: id, type: type}) do
    %Event{
      topic: "context/items",
      data: %{
        error: "Unknown context",
        data: %{
          context: context,
          id: id,
          type: type
        }
      }
    }
  end
end
