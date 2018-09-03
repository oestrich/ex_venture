defmodule Game.Command.Use do
  @moduledoc """
  The "use" command
  """

  use Game.Command

  alias Game.Character
  alias Game.Effect
  alias Game.Item
  alias Game.Items

  commands(["use"])

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
  Use an item
  """
  def run(command, state)

  def run({item_name}, state = %{socket: socket, save: %{items: items}}) do
    items = Items.items_keep_instance(items)

    case Item.find_item(items, item_name) do
      {:error, :not_found} ->
        socket |> item_not_found(item_name)

      {:ok, item} ->
        state |> use_item(item)
    end
  end

  def run({}, %{socket: socket}) do
    message =
      gettext("You are not sure what to use. See {command}help use{/command} for more information.")

    socket |> @socket.echo(message)
  end

  defp item_not_found(socket, item_name) do
    message = gettext(~s("%{name}" could not be found.), name: item_name)
    socket |> @socket.echo(message)
  end

  defp use_item(%{socket: socket}, {_, item = %{is_usable: false}}) do
    message = gettext("%{name} could not be used", name: Format.item_name(item))
    socket |> @socket.echo(message)
  end

  defp use_item(state = %{socket: socket, user: user, save: save}, {instance, item}) do
    player_effects = save |> Item.effects_on_player()

    effects =
      (player_effects ++ item.effects)
      |> Item.filter_effects(item)

    effects = save.stats |> Effect.calculate(effects)

    Character.apply_effects(
      {:player, user},
      effects,
      {:player, user},
      Format.usee_item(item, target: {:player, user}, user: {:player, user})
    )

    description = Format.user_item(item, target: {:player, user}, user: {:player, user})

    effects_message = Enum.join([description | Format.effects(effects, {:player, user})], "\n")
    socket |> @socket.echo(effects_message)

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
