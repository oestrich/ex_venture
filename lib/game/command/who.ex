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
    #{help(:short)}

    Example:
    [ ] > {command}who{/command}

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

    state.socket |> @socket.echo(String.trim(message))
  end

  def run({name}, state), do: Info.run({name}, state)

  defp local_names(players) do
    {admins, players} =
      Enum.split_with(players, fn %{user: user} ->
        User.is_admin?(user)
      end)

    (admins ++ players)
    |> Enum.map(fn %{user: user, metadata: metadata} ->
      Format.Who.player_line(user, metadata)
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
        """

        Remote players (on {white}Gossip{/white}):
        #{Enum.join(names, "\n")}
        """

      true ->
        ""
    end
  end
end
