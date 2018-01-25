defmodule Game.Command.Mistake do
  @moduledoc """
  Module to capture common mistakes.
  """

  use Game.Command

  commands(["kill", "attack"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Mistakes"
  def help(:short), do: "Common command mistakes"

  def help(:full) do
    """
    #{help(:short)}. This command catches common mistakes and directs you
    to more information about the subject.
    """
  end

  @impl Game.Command
  @doc """
  Parse out extra information

      iex> Game.Command.Mistake.parse("kill")
      {:auto_combat}

      iex> Game.Command.Mistake.parse("attack")
      {:auto_combat}

      iex> Game.Command.Mistake.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(command :: String.t()) :: {atom}
  def parse(command)
  def parse("attack" <> _), do: {:auto_combat}
  def parse("kill" <> _), do: {:auto_combat}

  @impl Game.Command
  def run(command, state)

  def run({:auto_combat}, %{socket: socket}) do
    socket
    |> @socket.echo(
      "There is no auto combat. Please read {white}help combat{/white} for more information."
    )

    :ok
  end
end
