defmodule Web.Quest do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Quest
  alias Data.QuestStep
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  Load all quests
  """
  @spec all(opts :: Keyword.t) :: [Quest.t]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Quest
    |> preload([:giver])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"level_from", level}, query) do
    query |> where([q], q.level >= ^level)
  end
  def filter_on_attribute({"level_to", level}, query) do
    query |> where([q], q.level <= ^level)
  end
  def filter_on_attribute(_, query), do: query

  @doc """
  Get a quest
  """
  @spec get(integer()) :: Quest.t
  def get(id) do
    Quest
    |> where([c], c.id == ^id)
    |> preload([:giver, quest_steps: [:item, :npc]])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Quest{} |> Quest.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Quest.t) :: Ecto.Changeset.t()
  def edit(quest), do: quest |> Quest.changeset(%{})

  @doc """
  Create a race
  """
  @spec create(map) :: {:ok, Quest.t} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %Quest{}
    |> Quest.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a quest
  """
  @spec update(integer(), map()) :: {:ok, Quest.t()} | {:error, Ecto.Changeset.t()}
  def update(id, params) do
    id
    |> get()
    |> Quest.changeset(params)
    |> Repo.update
  end

  #
  # Steps
  #

  @doc """
  Get a quest step
  """
  @spec get_step(integer()) :: QuestStep.t()
  def get_step(id) do
    QuestStep
    |> where([c], c.id == ^id)
    |> preload([:quest])
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new_step(Quest.t()) :: Ecto.Changeset.t()
  def new_step(quest) do
    quest
    |> Ecto.build_assoc(:quest_steps)
    |> QuestStep.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit_step(QuestStep.t) :: Ecto.Changeset.t()
  def edit_step(step), do: step |> QuestStep.changeset(%{})

  @doc """
  Create a quest step
  """
  @spec create_step(Quest.t(), map()) :: {:ok, QuestStep.t()} | {:error, Ecto.Changeset.t()}
  def create_step(quest, params) do
    quest
    |> Ecto.build_assoc(:quest_steps)
    |> QuestStep.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a quest step
  """
  @spec update_step(integer(), map()) :: {:ok, QuestStep.t()} | {:error, Ecto.Changeset.t()}
  def update_step(step_id, params) do
    step_id
    |> get_step()
    |> QuestStep.changeset(params)
    |> Repo.update()
  end
end
