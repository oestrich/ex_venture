defmodule Game.Command.Help do
  @moduledoc """
  The "help" command
  """

  use Game.Command

  @commands ["help"]

  alias Game.Help

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
