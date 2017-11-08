defmodule Game.Command.Help do
  @moduledoc """
  The "help" command
  """

  use Game.Command

  commands ["help"]

  alias Game.Help

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
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, state) do
    {:paginate, Help.base(), state}
  end
  def run({topic}, _session, state) do
    {:paginate, Help.topic(topic), state}
  end
end
