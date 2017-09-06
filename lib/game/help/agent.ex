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

  @doc """
  Add a newly added topic to the agent
  """
  def add(help_topic) do
    Agent.update(__MODULE__, fn (topics) -> [help_topic | topics] end)
  end

  @doc """
  Update a help topic already in the agent
  """
  def update(help_topic) do
    Agent.update(__MODULE__, fn (topics) ->
      topics = Enum.reject(topics, &(&1.id == help_topic.id))
      [help_topic | topics]
    end)
  end
end
