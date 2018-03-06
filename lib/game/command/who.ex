defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

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

  def run({}, %{socket: socket}) do
    players = Session.Registry.connected_players()

    names =
      players
      |> Enum.map(fn {_pid, user} ->
        prompt = "[#{user.save.level} #{user.class.name} #{user.race.name}]"
        "#{prompt} #{Format.player_name(user)} #{Format.player_flags(user, none: false)}"
      end)
      |> Enum.join("\n")

    socket |> @socket.echo("There are #{players |> length} players online:\n#{names}")
    :ok
  end

  def run({name}, state), do: Info.run({name}, state)
end
