defmodule Game.Help.Agent do
  @moduledoc """
  Agent for holding cached help topics

  To reduce database loading
  """

  alias Game.Help.Repo

  def start_link() do
    Agent.start_link(fn () -> _all() end, name: __MODULE__)
  end

  defp _all() do
    Repo.all()
  end

  @doc """
  Get all help topics in the agent
  """
  def all() do
    Agent.get(__MODULE__, fn (topics) -> topics end)
  end
end
