defmodule Game.Command.Debug do
  @moduledoc """
  The "afk" command
  """

  use Game.Command

  commands(["debug"], parse: false)

  @required_flags ["admin"]

  @impl Game.Command
  def help(:topic), do: "Debug"
  def help(:short), do: "Look up debug information"

  def help(:full) do
    """
    #{help(:short)}. For admins only.

    Example:
    [ ] > {command}debug info{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Debug.parse("debug info")
      {:squabble}

      iex> Game.Command.Debug.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("debug info"), do: {:squabble}

  @impl Game.Command
  def run(command, state)

  def run({:squabble}, state) do
    case "admin" in state.user.flags do
      true ->
        state.socket |> @socket.echo(String.trim(debug()))

      false ->
        state.socket |> @socket.echo(gettext("You must be an admin to use this command."))
    end
  end

  defp debug() do
    """
    {green}Debug Info{/green}
    -------------

    {white}Node{/white}: #{node()}
    {white}Session PID{/white}: #{inspect(self())}

    {green}Squabble{/green}
    -------

    #{squabble()}
    """
  end

  defp squabble() do
    Squabble.debug()
    |> Enum.map(fn debug ->
      """
      {white}Node{/white}: #{debug.node}
      {white}State{/white}: #{debug.state}
      {white}Term{/white}: #{debug.term}
      {white}Leader{/white}: #{debug.leader_node}
      """
    end)
    |> Enum.join("\n")
  end
end
