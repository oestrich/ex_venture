defmodule Game.Command.Mistake do
  @moduledoc """
  Module to capture common mistakes.
  """

  use Game.Command

  @custom_parse true
  @commands ["kill", "attack"]
  @help false

  @doc """
  Parse out extra information

      iex> Game.Command.Mistake.parse("kill")
      {:auto_combat}

      iex> Game.Command.Mistake.parse("attack")
      {:auto_combat}

      iex> Game.Command.Mistake.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("attack" <> _), do: {:auto_combat}
  def parse("kill" <> _), do: {:auto_combat}
  def parse(command), do: {:error, :bad_parse, command}

  @spec run(args :: {atom, String.t}, session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({:auto_combat}, _session, %{socket: socket}) do
    socket |> @socket.echo("There is no auto combat. Please read {white}help combat{/white} for more information.")
    :ok
  end
end
