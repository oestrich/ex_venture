defmodule Kantele.Character.ItemCommand do
  use Kalevala.Character.Command

  alias Kalevala.Verb
  alias Kantele.Character.ItemView
  alias Kantele.World.Items

  def drop(conn, %{"item_name" => item_name}) do
    item_instance =
      Enum.find(conn.character.inventory, fn item_instance ->
        item = Items.get!(item_instance.item_id)
        item_instance.id == item_name || item.callback_module.matches?(item, item_name)
      end)

    case !is_nil(item_instance) do
      true ->
        item = Items.get!(item_instance.item_id)

        case Verb.has_matching_verb?(item.verbs, :drop, %Verb.Context{location: "inventory/self"}) do
          true ->
            conn
            |> request_item_drop(item_instance)
            |> assign(:prompt, false)

          false ->
            conn
            |> assign(:item, item)
            |> assign(:reason, :missing_verb)
            |> render(ItemView, "drop-abort")
        end

      false ->
        render(conn, ItemView, "unknown", %{item_name: item_name})
    end
  end

  def get(conn, %{"item_name" => item_name}) do
    conn
    |> request_item_pickup(item_name)
    |> assign(:prompt, false)
  end
end
