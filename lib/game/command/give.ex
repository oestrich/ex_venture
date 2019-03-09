defmodule Game.Command.Give do
  @moduledoc """
  The "give" command
  """

  use Game.Command
  use Game.Currency
  use Game.Zone

  import Game.Room.Helpers, only: [find_character: 2]

  alias Game.Character
  alias Game.Events.CurrencyReceived
  alias Game.Events.ItemReceived
  alias Game.Format
  alias Game.Item
  alias Game.Items
  alias Game.Player

  commands(["give"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Give"
  def help(:short), do: "Give items to players"

  def help(:full) do
    """
    #{help(:short)}. Give an item to a player or NPC in your room.

    [ ] > {command}give potion to guard{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Give.parse("give potion to guard")
      {"potion", :to, "guard"}

      iex> Game.Command.Give.parse("give potion guard")
      {:error, :bad_parse, "give potion guard"}

      iex> Game.Command.Give.parse("give extra")
      {:error, :bad_parse, "give extra"}

      iex> Game.Command.Give.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("give " <> item_to_character), do: _parse_give_command(item_to_character)

  @doc """
  Handle the common parsing code for an item name and then the character
  """
  @spec _parse_give_command(String.t()) :: :ok
  def _parse_give_command(string) do
    case Regex.run(~r/(?<item>.+) to (?<character>.+)/i, string, capture: :all) do
      nil ->
        {:error, :bad_parse, "give " <> string}

      [_string, item_name, character_name] ->
        {String.trim(item_name), :to, character_name}
    end
  end

  @impl Game.Command
  @doc """
  Give items to another character
  """
  def run(command, state)

  def run({item_name, :to, character_name}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case find_item_or_currency(state.save, item_name) do
      {:error, :not_found} ->
        message = gettext("\"%{name}\" could not be found.", name: item_name)
        state |> Socket.echo(message)

      {:ok, instance, item} ->
        state |> maybe_give_to_character(room, instance, item, character_name)
    end
  end

  defp find_item_or_currency(save, item_name) do
    case Regex.match?(~r/^\d+ #{@currency}$/, item_name) do
      false ->
        find_item(save, item_name)

      true ->
        [currency | _] = String.split(item_name, " ")
        {:ok, String.to_integer(currency), :currency}
    end
  end

  defp find_item(save, item_name) do
    items = Items.items_keep_instance(save.items)

    item =
      Enum.find(items, fn {_instance, item} ->
        Item.matches_lookup?(item, item_name)
      end)

    case item do
      nil ->
        {:error, :not_found}

      {instance, item} ->
        {:ok, instance, item}
    end
  end

  defp maybe_give_to_character(state, room, instance, item, character_name) do
    case find_character(room, character_name) do
      {:error, :not_found} ->
        message = gettext("\"%{name}\" could not be found.", name: character_name)
        state |> Socket.echo(message)

      {:ok, character} ->
        send_item_to_character(state, instance, item, character)
    end
  end

  defp send_item_to_character(state = %{save: save}, currency, :currency, character) do
    case save.currency >= currency do
      false ->
        message =
          gettext("You do not have enough %{currency} to give to %{name}.",
            currency: currency(),
            name: Format.name(character)
          )

        state |> Socket.echo(message)

      true ->
        message =
          gettext("Gave %{currency} to %{name}.",
            currency: Format.currency(currency),
            name: Format.name(character)
          )

        Socket.echo(state, message)

        event = %CurrencyReceived{character: Character.to_simple(state.character), amount: currency}
        Character.notify(character, event)

        state = Player.update_save(state, %{save | currency: save.currency - currency})

        {:update, state}
    end
  end

  defp send_item_to_character(state = %{save: save}, instance, item, character) do
    message =
      gettext("Gave %{item} to %{name}.",
        item: Format.item_name(item),
        name: Format.name(character)
      )

    state |> Socket.echo(message)

    event = %ItemReceived{character: Character.to_simple(state.character), instance: instance}
    Character.notify(character, event)

    items = List.delete(save.items, instance)
    state = Player.update_save(state, %{save | items: items})

    {:update, state}
  end
end
