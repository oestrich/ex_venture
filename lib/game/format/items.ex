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
    context()
    |> assign(:name, item.name)
    |> Format.template("{item}[name]{/item}")
  end

  @doc """
  Format currency
  """
  @spec currency(Save.t() | Room.t()) :: String.t()
  def currency(%{currency: currency}) when currency == 0, do: ""

  def currency(%{currency: amount}) do
    currency(amount)
  end

  def currency(amount) do
    context()
    |> assign(:amount, amount)
    |> assign(:currency, @currency)
    |> Format.template("{item}[amount] [currency]{/item}")
  end

  @doc """
  Display an item

  Example:

      iex> string = Items.item(%{name: "Short Sword", description: "A simple blade"})
      iex> Regex.match?(~r(Short Sword), string)
      true
  """
  @spec item(Item.t()) :: String.t()
  def item(item) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:underline, Format.underline(item.name))
    |> assign(:description, item.description)
    |> assign(:stats, item_stats(item))
    |> Format.template(render("item"))
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
    context()
    |> assign(:slot, stats.slot)
    |> Format.template("Slot: [slot]")
  end

  def item_stats(_), do: ""

  @doc """
  Format your inventory
  """
  @spec inventory(integer(), map(), map(), [Item.t()]) :: String.t()
  def inventory(currency_amount, wearing, wielding, items) do
    items =
      items
      |> Enum.map(&inventory_item/1)
      |> Enum.join("\n")

    context()
    |> assign(:equipment, equipment(wearing, wielding))
    |> assign(:items, items)
    |> assign(:currency, currency(currency_amount))
    |> Format.template(render("inventory"))
  end

  def inventory_item(%{item: item, quantity: 1}) do
    context()
    |> assign(:name, item_name(item))
    |> Format.template("  - [name]")
  end

  def inventory_item(%{item: item, quantity: quantity}) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:quantity, quantity)
    |> Format.template("  - {item}[name] x[quantity]{/item}")
  end

  @doc """
  Format your equipment

  Example:

      iex> wearing = %{chest: %{name: "Leather Armor"}}
      iex> wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      iex> Items.equipment(wearing, wielding)
      "You are wearing:\\n  - {item}Leather Armor{/item} on your chest\\nYou are wielding:\\n  - {item}Shield{/item} in your left hand\\n  - {item}Short Sword{/item} in your right hand"
  """
  @spec equipment(map(), map()) :: String.t()
  def equipment(wearing, wielding) do
    wearing =
      wearing
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(&wearing_item/1)
      |> Enum.join("\n")

    wielding =
      wielding
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(&wielding_item/1)
      |> Enum.join("\n")

    context()
    |> assign(:wearing, wearing)
    |> assign(:wielding, wielding)
    |> Format.template("You are wearing:\n[wearing]\nYou are wielding:\n[wielding]")
  end

  def wearing_item({part, item}) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:part, part)
    |> Format.template("  - [name] on your [part]")
  end

  def wielding_item({hand, item}) do
    context()
    |> assign(:name, item_name(item))
    |> assign(:hand, hand)
    |> Format.template("  - [name] in your [hand] hand")
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
      "{npc}NPC{/npc} dropped {item}Sword{/item}."

      iex> Items.dropped({:player, %{name: "Player"}}, %{name: "Sword"})
      "{player}Player{/player} dropped {item}Sword{/item}."

      iex> Items.dropped({:player, %{name: "Player"}}, {:currency, 100})
      "{player}Player{/player} dropped {item}100 gold{/item}."
  """
  @spec dropped(Character.t(), Item.t()) :: String.t()
  def dropped(who, {:currency, amount}) do
    context()
    |> assign(:character, Format.name(who))
    |> assign(:currency, currency(amount))
    |> Format.template("[character] dropped [currency].")
  end

  def dropped(who, item) do
    context()
    |> assign(:character, Format.name(who))
    |> assign(:name, item_name(item))
    |> Format.template("[character] dropped [name].")
  end

  def render("item") do
    """
    [name]
    [underline]
    [description]
    [stats]
    """
  end

  def render("inventory") do
    """
    [equipment]
    You are holding:
    [items]
    You have [currency].
    """
  end
end
