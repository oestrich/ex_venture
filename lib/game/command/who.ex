defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

  alias Game.Format

  commands(["who"])

  @impl Game.Command
  def help(:topic), do: "Who"
  def help(:short), do: "See who is online"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {white}who{/white}
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
        flags =
          user.flags
          |> Enum.map(&"{red}#{&1}{/red}")
          |> Enum.join(" ")

        prompt = "[#{user.save.level} #{user.class.name} #{user.race.name}]"
        "#{prompt} #{Format.player_name(user)} #{flags}"
      end)
      |> Enum.join("\n")

    socket |> @socket.echo("There are #{players |> length} players online:\n#{names}")
    :ok
  end
end
