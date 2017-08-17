defmodule Game.Command.Info do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Effect
  alias Game.Item

  @commands ["info"]

  @short_help "View stats about your character"
  @full_help """
  Example: info
  """

  @doc """
  Look at your info sheet
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, user: user, save: save}) do
    effects = save |> Item.effects_from_wearing()
    {stats, _} = save.stats |> Effect.calculate_stats(effects)
    socket |> @socket.echo(Format.info(%{user | save: %{save | stats: stats}}))
    :ok
  end
end
