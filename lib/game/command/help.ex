defmodule Game.Command.Help do
  @moduledoc """
  The "help" command
  """

  use Game.Command

  commands(["help"])

  alias Game.Color
  alias Game.Help

  @impl Game.Command
  def help(:topic), do: "Help"
  def help(:short), do: "View information about commands and other topics"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {command}help{/command}
    [ ] > {command}help move{/command}
    """
  end

  @impl Game.Command
  @doc """
  View help
  """
  def run(command, state)

  def run({}, state) do
    {:paginate, Help.base(state.user.flags), state}
  end

  def run({topic}, state) do
    help =
      topic
      |> Help.topic(state.user.flags)
      |> Color.delink_commands()

    {:paginate, help, state}
  end
end
