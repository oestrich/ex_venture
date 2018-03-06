defmodule Game.Command.PickUp do
  @moduledoc """
  The "pick up" command
  """

  use Game.Command
  use Game.Currency

  require Logger

  alias Game.Items

  @must_be_alive true

  commands([{"pick up", ["get", "take"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Pick Up"
  def help(:short), do: "Pick up an item in the same room"

  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {command}pick up sword{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.PickUp.parse("pick up")
      {"pick up", :help}
      iex> Game.Command.PickUp.parse("get")
      {"get", :help}
      iex> Game.Command.PickUp.parse("take")
      {"take", :help}

      iex> Game.Command.PickUp.parse("pick up item")
      {"item"}

      iex> Game.Command.PickUp.parse("get item")
      {"item"}

      iex> Game.Command.PickUp.parse("take item")
      {"item"}

      iex> Game.Command.PickUp.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("pick up"), do: {"pick up", :help}
  def parse("get"), do: {"get", :help}
  def parse("take"), do: {"take", :help}
  def parse("pick up " <> item), do: {item}
  def parse("get " <> item), do: {item}
  def parse("take " <> item), do: {item}

  @impl Game.Command
  @doc """
  Pick up an item from a room
  """
  def run(command, state)

  def run({@currency}, state = %{socket: socket, save: save}) do
    case @room.pick_up_currency(save.room_id) do
      {:ok, currency} ->
        Logger.info(
          "Session (#{inspect(self())}) picking up #{currency} currency from room (#{save.room_id})",
          type: :player
        )

        save = %{save | currency: save.currency + currency}
        socket |> @socket.echo("You picked up #{currency} #{@currency}")
        {:update, Map.put(state, :save, save)}

      _ ->
        socket |> @socket.echo(~s("#{@currency}" could not be found))
        :ok
    end
  end

  def run({item_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    instance =
      room.items
      |> Enum.find(fn instance ->
        item = Items.item(instance)
        Game.Item.matches_lookup?(item, item_name)
      end)

    case instance do
      nil ->
        socket |> @socket.echo(~s("#{item_name}" could not be found))
        :ok

      instance ->
        pick_up(instance, room, state)
    end
  end

  def run({verb, :help}, %{socket: socket}) do
    socket
    |> @socket.echo(
      "You don't know what to #{verb}. See {command}help get{/command} for more information."
    )

    :ok
  end

  def pick_up(item, room, state = %{socket: socket, save: save}) do
    case @room.pick_up(room.id, item) do
      {:ok, instance} ->
        item = Items.item(instance)

        Logger.info(
          "Session (#{inspect(self())}) picking up item (#{item.id}) from room (#{room.id})",
          type: :player
        )

        save = %{save | items: [instance | save.items]}
        socket |> @socket.echo("You picked up the #{Format.item_name(item)}")
        {:update, Map.put(state, :save, save)}

      _ ->
        socket |> @socket.echo(~s("#{item.name}" could not be found))
        :ok
    end
  end
end
