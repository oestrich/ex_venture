defmodule Game.Command.Listen do
  @moduledoc """
  The "listen" command
  """

  use Game.Command

  alias Data.Exit
  alias Game.Environment.State.Overworld
  alias Game.Format.Listen, as: FormatListen
  alias Game.Room.Helpers, as: RoomHelpers

  commands(["listen"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Listen"
  def help(:short), do: "Listen to your surroundings"

  def help(:full) do
    """
    This will return anything that can be heard from your surroundings including
    the room, it's features, and any NPCs in the room. You can direct your listening
    towards a room's exit and listen in on the adjacent room.

    Listen to the current room:
    [ ] > {command}listen{/command}

    Listen to an adjacent room:
    [ ] > {command}listen north{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Listen.parse("listen")
      {}

      iex> Game.Command.Listen.parse("listen north")
      {"north"}

      iex> Game.Command.Listen.parse("listen outside")
      {:error, :bad_parse, "listen outside"}

      iex> Game.Command.Listen.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("listen"), do: {}

  def parse("listen " <> direction) do
    case Exit.exit?(direction) do
      true ->
        {direction}

      false ->
        {:error, :bad_parse, "listen " <> direction}
    end
  end

  @impl Game.Command
  def run(command, state)

  def run({}, state = %{save: save}) do
    {:ok, room} = @environment.look(save.room_id)

    case room_has_noises?(room) do
      true ->
        state.socket |> @socket.echo(FormatListen.to_room(room))

      false ->
        state.socket |> @socket.echo(gettext("Nothing can be heard."))
    end
  end

  def run({direction}, state = %{save: save}) do
    {:ok, room} = @environment.look(save.room_id)

    with {:ok, room} <- room |> RoomHelpers.get_exit(direction),
         true <- room_has_noises?(room) do
      state.socket |> @socket.echo(FormatListen.to_room(room))
    else
      {:error, :not_found} ->
        state.socket |> @socket.echo(gettext("There is no exit that direction to listen to."))

      _ ->
        state.socket |> @socket.echo(gettext("Nothing can be heard."))
    end
  end

  defp room_has_noises?(room) do
    case room do
      %Overworld{} ->
        false

      _ ->
        !is_nil(room.listen) || npc_listens_present?(room) || feature_listens_present?(room)
    end
  end

  defp npc_listens_present?(room) do
    Enum.any?(room.npcs, &(listen_present?(&1.extra.status_listen)))
  end

  defp feature_listens_present?(room) do
    Enum.any?(room.features, &(listen_present?(&1.listen)))
  end

  defp listen_present?(nil), do: false
  defp listen_present?(""), do: false
  defp listen_present?(_str), do: true
end
