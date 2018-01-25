defmodule Game.Command.Info do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Account
  alias Game.Effect
  alias Game.Item

  commands([{"info", ["score"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Info"
  def help(:short), do: "View stats about your character"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {white}info{/white}
    """
  end

  @impl Game.Command
  def parse(command)
  def parse("info"), do: {}
  def parse("score"), do: {}

  @impl Game.Command
  @doc """
  Look at your info sheet
  """
  def run(command, state)

  def run({}, state = %{socket: socket, user: user, save: save}) do
    user = %{user | save: cacluate_save(save), seconds_online: seconds_online(user, state)}
    socket |> @socket.echo(Format.info(user))
    :ok
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
