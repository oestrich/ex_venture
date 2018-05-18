defmodule Web.HelpTopic do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query
  import Web.KeywordsHelper

  alias Data.HelpTopic
  alias Data.Repo
  alias Game.Command
  alias Game.Help.Agent, as: HelpAgent
  alias Web.Pagination

  @doc """
  Get all help_topics
  """
  @spec all(opts :: Keyword.t()) :: [HelpTopic.t()]
  def all(opts \\ [])

  def all(alpha: true) do
    help_topics = HelpAgent.database()
    built_ins = HelpAgent.built_in()

    (help_topics ++ built_ins)
    |> Enum.sort_by(&(&1.name))
  end

  def all(opts) do
    opts = Enum.into(opts, %{})

    HelpTopic
    |> order_by([ht], ht.id)
    |> Pagination.paginate(opts)
  end

  @doc """
  Get a list of commands the game has, as a string. From the `Game.Command` module.
  """
  @spec commands() :: [String.t()]
  def commands() do
    Game.Command.commands()
    |> Enum.map(fn command ->
      command |> to_string |> String.split(".") |> List.last()
    end)
    |> Enum.sort()
  end

  @doc """
  Find a command that matches the topic
  """
  @spec command(String.t()) :: Command.t()
  def command(topic) do
    case Enum.find(Command.commands(), &match_command?(&1, topic)) do
      nil ->
        {:error, :not_found}

      topic ->
        {:ok, topic}
    end
  end

  defp match_command?(command, topic) do
    command_name =
      command
      |> to_string()
      |> String.split(".")
      |> List.last()
      |> String.downcase()

    command_name == topic |> String.downcase()
  end

  def built_in(id) do
    HelpAgent.built_in()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Get a help topic
  """
  @spec get(id :: integer) :: [HelpTopic.t()]
  def get(id) do
    HelpTopic
    |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %HelpTopic{} |> HelpTopic.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(help_topic :: HelpTopic.t()) :: changeset :: map
  def edit(help_topic), do: help_topic |> HelpTopic.changeset(%{})

  @doc """
  Create a help topic
  """
  @spec create(params :: map) :: {:ok, HelpTopic.t()} | {:error, changeset :: map}
  def create(params) do
    changeset = %HelpTopic{} |> HelpTopic.changeset(cast_params(params))

    case changeset |> Repo.insert() do
      {:ok, help_topic} ->
        HelpAgent.add(help_topic)
        {:ok, help_topic}

      anything ->
        anything
    end
  end

  @doc """
  Update a help topic
  """
  @spec update(id :: integer, params :: map) :: {:ok, HelpTopic.t()} | {:error, changeset :: map}
  def update(id, params) do
    help_topic = id |> get()
    changeset = help_topic |> HelpTopic.changeset(cast_params(params))

    case changeset |> Repo.update() do
      {:ok, help_topic} ->
        HelpAgent.update(help_topic)
        {:ok, help_topic}

      anything ->
        anything
    end
  end

  defp cast_params(params) do
    params
    |> split_keywords()
  end
end
