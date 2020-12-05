defmodule Kantele.Character.InventoryView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.Event
  alias Kalevala.Character.Conn.EventText
  alias Kantele.Character.ItemView

  def render("list.event", %{item_instances: item_instances}) do
    %Event{
      topic: "Inventory.All",
      data: %{
        item_instances: item_instances
      }
    }
  end

  def render("list", %{item_instances: item_instances}) do
    %EventText{
      topic: "Inventory.All",
      data: %{
        item_instances: item_instances
      },
      text: ~E"""
      You are holding:
      <%= render("_items", %{item_instances: item_instances}) %>
      """
    }
  end

  def render("_items", %{item_instances: item_instances}) do
    item_instances
    |> Enum.map(&render("_item", %{item_instance: &1}))
    |> View.join("\n")
  end

  def render("_item", %{item_instance: item_instance}) do
    ~i(- #{ItemView.render("name", %{item_instance: item_instance, context: :inventory})})
  end
end
