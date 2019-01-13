defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

  alias Data.User
  alias Game.Command.Info
  alias Game.Format

  commands(["who"])

  @impl Game.Command
  def help(:topic), do: "Who"
  def help(:short), do: "See who is online"

  def help(:full) do
    """
    See who is online currently.

    Any admins will show up first in the list.

    Example:
    [ ] > {command}who{/command}

    You can also view more information about a player connected. Similar
    to {command}info player{/command}.

    [ ] > {command}who player{/command}
    """
  end

  @doc """
  Echo the currently connected players
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)

  def run({}, state) do
    players = Session.Registry.connected_players()

    message = """
    There are #{length(players)} players online:
    #{local_names(players)}
    #{remote_names()}
    """

    state |> Socket.echo(String.trim(message))
  end

  def run({name}, state), do: Info.run({name}, state)

  defp local_names(players) do
    {admins, players} =
      Enum.split_with(players, fn %{player: player} ->
        User.is_admin?(player.extra)
      end)

    (admins ++ players)
    |> Enum.map(fn %{player: player, metadata: metadata} ->
      Format.Who.player_line(player, metadata)
    end)
    |> Enum.join("\n")
  end

  defp remote_names() do
    names =
      Gossip.who()
      |> Enum.flat_map(fn {game_name, players} ->
        Enum.map(players, &Format.Who.remote_player_line(game_name, &1))
      end)
      |> Enum.sort()

    case Enum.empty?(names) do
      false ->
        names = Enum.join(names, "\n")
        "\nRemote players (on {white}Gossip{/white}):\n#{names}"

      true ->
        ""
    end
  end
end
