defmodule Game.Format.Items do
  @moduledoc """
  Format functions for items
  """

  use Game.Currency

  import Game.Format.Context

  alias Data.Item
  alias Game.Format

  @doc """
  Format an items name, cyan

    iex> Items.item_name(%{name: "Potion"})
    "{item}Potion{/item}"
  """
  @spec item_name(Item.t()) :: String.t()
  def item_name(item) do
    "{item}#{item.name}{/item}"
  end

  @doc """
  Format currency
  """
  @spec currency(Save.t() | Room.t()) :: String.t()
  def currency(%{currency: currency}) when currency == 0, do: ""
  def currency(%{currency: currency}), do: "{cyan}#{currency} #{@currency}{/cyan}"
  def currency(currency) when is_integer(currency), do: "{cyan}#{currency} #{@currency}{/cyan}"

  @doc """
  Display an item

  Example:

      iex> string = Items.item(%{name: "Short Sword", description: "A simple blade"})
      iex> Regex.match?(~r(Short Sword), string)
      true
  """
  @spec item(Item.t()) :: String.t()
  def item(item) do
    """
    #{item |> item_name()}
    #{item.name |> Format.underline}
    #{item.description}
    #{item_stats(item)}
    """
    |> String.trim()
    |> Format.resources()
  end

  @doc """
  Format an items stats

      iex> Items.item_stats(%{type: "armor", stats: %{slot: :chest}})
      "Slot: chest"

      iex> Items.item_stats(%{type: "basic"})
      ""
  """
  @spec item_stats(Item.t()) :: String.t()
  def item_stats(item)

  def item_stats(%{type: "armor", stats: stats}) do
    "Slot: #{stats.slot}"
  end

  def item_stats(_), do: ""

  @doc """
  Format your inventory
  """
  @spec inventory(integer(), map(), map(), [Item.t()]) :: String.t()
  def inventory(currency, wearing, wielding, items) do
    items =
      items
      |> Enum.map(fn
        %{item: item, quantity: 1} -> "  - #{item_name(item)}"
        %{item: item, quantity: quantity} -> "  - {item}#{item.name} x#{quantity}{/item}"
      end)
      |> Enum.join("\n")

    """
    #{equipment(wearing, wielding)}
    You are holding:
    #{items}
    You have #{currency} #{@currency}.
    """
    |> String.trim()
  end

  @doc """
  Format your equipment

  Example:

      iex> wearing = %{chest: %{name: "Leather Armor"}}
      iex> wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      iex> Items.equipment(wearing, wielding)
      "You are wearing:\\n  - {item}Leather Armor{/item} on your chest\\nYou are wielding:\\n  - a {item}Shield{/item} in your left hand\\n  - a {item}Short Sword{/item} in your right hand"
  """
  @spec equipment(map(), map()) :: String.t()
  def equipment(wearing, wielding) do
    wearing =
      wearing
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {part, item} -> "  - #{item_name(item)} on your #{part}" end)
      |> Enum.join("\n")

    wielding =
      wielding
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {hand, item} -> "  - a #{item_name(item)} in your #{hand} hand" end)
      |> Enum.join("\n")

    ["You are wearing:", wearing, "You are wielding:", wielding]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  @doc """
  Message for users of items

      iex> Items.user_item(%{name: "Potion", user_text: "You used [name] on [target]."}, target: {:npc, %{name: "Bandit"}}, user: {:player, %{name: "Player"}})
      "You used {item}Potion{/item} on {npc}Bandit{/npc}."
  """
  def user_item(item, opts \\ []) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:target, Format.target_name(Keyword.get(opts, :target)))
    |> assign(:user, Format.target_name(Keyword.get(opts, :user)))
    |> Format.template(item.user_text)
  end

  @doc """
  Message for usees of items

      iex> Items.usee_item(%{name: "Potion", usee_text: "You used [name] on [target]."}, target: {:npc, %{name: "Bandit"}}, user: {:player, %{name: "Player"}})
      "You used {item}Potion{/item} on {npc}Bandit{/npc}."
  """
  def usee_item(item, opts \\ []) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:target, Format.target_name(Keyword.get(opts, :target)))
    |> assign(:user, Format.target_name(Keyword.get(opts, :user)))
    |> Format.template(item.usee_text)
  end

  @doc """
  An item was dropped message

      iex> Items.dropped({:npc, %{name: "NPC"}}, %{name: "Sword"})
      "{npc}NPC{/npc} dropped a {item}Sword{/item}."

      iex> Items.dropped({:player, %{name: "Player"}}, %{name: "Sword"})
      "{player}Player{/player} dropped a {item}Sword{/item}."

      iex> Items.dropped({:player, %{name: "Player"}}, {:currency, 100})
      "{player}Player{/player} dropped {item}100 gold{/item}."
  """
  @spec dropped(Character.t(), Item.t()) :: String.t()
  def dropped(who, {:currency, amount}) do
    "#{Format.name(who)} dropped {item}#{amount} #{currency()}{/item}."
  end

  def dropped(who, item) do
    "#{Format.name(who)} dropped a #{item_name(item)}."
  end
end
