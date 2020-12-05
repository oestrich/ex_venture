defmodule Kantele.Character.ItemView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText

  def render("name", %{item_instance: item_instance} = attributes) do
    context = Map.get(attributes, :context, :none)

    item = item_instance.item

    [
      ~i({item-instance id="#{item_instance.id}" context="#{context}" name="#{item.name}" description="#{
        item.description
      }"}),
      render("name", %{item: item}),
      ~i({/item-instance})
    ]
  end

  def render("name", %{item: item}) do
    ~i({item id="#{item.id}"}#{item.name}{/item})
  end

  def render("drop-abort", %{reason: :missing_verb, item: item}) do
    ~i(You cannot drop #{render("name", %{item: item})})
  end

  def render("drop-commit", %{item_instance: item_instance}) do
    %EventText{
      topic: "Inventory.DropItem",
      data: %{item_instance: item_instance},
      text: ~i(You dropped #{render("name", %{item_instance: item_instance, context: :room})}.\n)
    }
  end

  def render("pickup-abort", %{reason: :missing_verb, item: item}) do
    ~i(You cannot pick up #{render("name", %{item: item})}\n)
  end

  def render("pickup-commit", %{item_instance: item_instance}) do
    %EventText{
      topic: "Inventory.PickupItem",
      data: %{item_instance: item_instance},
      text:
        ~i(You picked up #{render("name", %{item_instance: item_instance, context: :inventory})}.\n)
    }
  end

  def render("unknown", %{item_name: item_name}) do
    ~i(There is no item {color foreground="white"}"#{item_name}"{/color}.\n)
  end
end
