defmodule Kantele.Character.ContextEvent do
  use Kalevala.Character.Event

  alias Kalevala.Verb
  alias Kalevala.World.Item
  alias Kantele.Character.ContextView
  alias Kantele.World.Items

  def lookup(conn, %{data: %{"context" => "room", "type" => "item", "id" => id}}) do
    event(conn, "context/lookup", %{type: :item, id: id})
  end

  def lookup(conn, %{data: %{"context" => "inventory", "type" => "item", "id" => id}}) do
    item_instance =
      Enum.find(conn.character.inventory, fn item_instance ->
        item_instance.id == id
      end)

    case item_instance != nil do
      true ->
        item = Items.get!(item_instance.item_id)

        verbs = Item.context_verbs(item, %{location: "inventory/self"})
        verbs = Verb.replace_variables(verbs, %{id: item_instance.id})

        conn
        |> assign(:context, "inventory")
        |> assign(:item_instance, item_instance)
        |> assign(:verbs, verbs)
        |> render(ContextView, "item")

      false ->
        handle_unknown(conn, "inventory", "item", id)
    end
  end

  def lookup(conn, %{data: %{"context" => context, "type" => type, "id" => id}}) do
    handle_unknown(conn, context, type, id)
  end

  defp handle_unknown(conn, context, type, id) do
    conn
    |> assign(:context, context)
    |> assign(:type, type)
    |> assign(:id, id)
    |> render(ContextView, "unknown")
  end
end
