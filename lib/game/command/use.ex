defmodule Game.Command.Use do
  @moduledoc """
  The "use" command
  """

  use Game.Command

  alias Game.Character
  alias Game.Effect
  alias Game.Format.Effects, as: FormatEffects
  alias Game.Format.Items, as: FormatItems
  alias Game.Item
  alias Game.Items
  alias Game.Utility

  commands(["use"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Use"
  def help(:short), do: "Use an item from your inventory"

  def help(:full) do
    """
    Use an item in your inventory.

    Example:
    [ ] > {command}use potion{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Use.parse("use item")
      {:use, "item"}

      iex> Game.Command.Use.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("use " <> item), do: {:use, item}
  def parse("use"), do: {}

  @impl Game.Command
  def parse(command, context)

  def parse(command, %{player: %{save: save}}) do
    item =
      save.items
      |> Items.items()
      |> Enum.reject(&Utility.empty_string?(&1.usage_command))
      |> Enum.find(fn item ->
        Utility.matches?(command, item.usage_command)
      end)

    case item do
      nil ->
        parse(command)

      item ->
        {:use, Utility.strip_leading_text(item.usage_command, command)}
    end
  end

  @impl Game.Command
  @doc """
  Use an item
  """
  def run(command, state)

  def run({:use, item_name}, state = %{save: %{items: items}}) do
    items = Items.items_keep_instance(items)

    case Item.find_item(items, item_name) do
      {:error, :not_found} ->
        state |> item_not_found(item_name)

      {:ok, item} ->
        state |> use_item(item)
    end
  end

  def run({}, state) do
    message = "You are not sure what to use. See {command}help use{/command} for more information."
    state |> Socket.echo(message)
  end

  defp item_not_found(state, item_name) do
    message = ~s("#{item_name}" could not be found.)
    state |> Socket.echo(message)
  end

  defp use_item(state, {_, item = %{is_usable: false}}) do
    name = FormatItems.item_name(item)
    message = "#{name} could not be used"
    state |> Socket.echo(message)
  end

  defp use_item(state = %{save: save}, {instance, item}) do
    player_effects = save |> Item.effects_on_player()

    effects =
      (player_effects ++ item.effects)
      |> Item.filter_effects(item)

    effects = save.stats |> Effect.calculate(effects)

    usee_text =
      FormatItems.usee_item(item,
        target: Character.to_simple(state.character),
        user: Character.to_simple(state.character)
      )

    Character.apply_effects(
      Character.to_simple(state.character),
      effects,
      Character.to_simple(state.character),
      usee_text
    )

    description =
      FormatItems.user_item(item,
        target: Character.to_simple(state.character),
        user: Character.to_simple(state.character)
      )

    effects_message =
      Enum.join([description | FormatEffects.effects(effects, Character.to_simple(state.character))], "\n")

    state |> Socket.echo(effects_message)

    spend_item(state, instance)
  end

  defp spend_item(_, %{amount: -1}) do
    {:skip, :prompt}
  end

  defp spend_item(state = %{save: %{items: items}}, instance) do
    items = List.delete(items, instance)
    # ensure item is good to go
    instance = Item.migrate_instance(instance)
    instance = %{instance | amount: instance.amount - 1}

    items =
      case instance do
        %{amount: 0} -> items
        _ -> [instance | items]
      end

    state = %{state | save: %{state.save | items: items}}
    {:skip, :prompt, state}
  end
end
