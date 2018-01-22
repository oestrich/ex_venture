defmodule Game.Command.Version do
  @moduledoc """
  The 'version' command
  """

  use Game.Command

  commands ["version"]

  @impl Game.Command
  def help(:topic), do: "Version"
  def help(:short), do: "View the running MUD version"
  def help(:full) do
    """
    View the full version of ExVenture running

    Example:
    [ ] > {white}version{/white}
    """
  end

  @doc """
  View version information
  """
  @impl Game.Command
  @spec run(args :: {atom, String.t}, state :: map) :: :ok
  def run(command, state)
  def run({}, %{socket: socket}) do
    socket |> @socket.echo("#{ExVenture.version()}\nhttp://exventure.org - https://github.com/oestrich/ex_venture")
    :ok
  end
end
