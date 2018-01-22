defmodule Game.Command.Help do
  @moduledoc """
  The "help" command
  """

  use Game.Command

  commands ["help"]

  alias Game.Help

  @impl Game.Command
  def help(:topic), do: "Help"
  def help(:short), do: "View information about commands and other topics"
  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {white}help{/white}
    [ ] > {white}help move{/white}
    """
  end

  @doc """
  View help
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)
  def run({}, state) do
    {:paginate, Help.base(), state}
  end
  def run({topic}, state) do
    {:paginate, Help.topic(topic), state}
  end
end
