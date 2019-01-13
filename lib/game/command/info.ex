defmodule Game.Command.Info do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Account
  alias Game.Effect
  alias Game.Format.Players, as: FormatPlayers
  alias Game.Item

  commands([{"info", ["score"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Info"
  def help(:short), do: "View stats about your character"

  def help(:full) do
    """
    #{help(:short)}. You can also view stats about another character.

    Example:
    [ ] > {command}info{/command}
    [ ] > {command}score{/command}

    [ ] > {command}info player{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Info.parse("info")
      {}
      iex> Game.Command.Info.parse("score")
      {}

      iex> Game.Command.Info.parse("info player")
      {"player"}

      iex> Game.Command.Info.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("info"), do: {}
  def parse("score"), do: {}
  def parse("info " <> name), do: {name}

  @impl Game.Command
  @doc """
  Look at your info sheet
  """
  def run(command, state)

  def run({}, state = %{character: character, save: save}) do
    character =
      character
      |> Map.put(:save, cacluate_save(save))
      |> Map.put(:seconds_online, seconds_online(state.character, state))

    state |> Socket.echo(FormatPlayers.info(character))
  end

  def run({name}, state) do
    case Account.get_player(name) do
      {:ok, player} ->
        state |> Socket.echo(FormatPlayers.short_info(player))

      {:error, :not_found} ->
        message = gettext("Could not find a player with the name \"%{name}\".", name: name)
        state |> Socket.echo(message)
    end
  end

  defp cacluate_save(save) do
    effects = save |> Item.effects_from_wearing()
    {stats, _} = save.stats |> Effect.calculate_stats(effects)
    %{save | stats: stats}
  end

  defp seconds_online(user, %{session_started_at: session_started_at}) do
    Account.current_play_time(user, session_started_at, Timex.now())
  end
end
