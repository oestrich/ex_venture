defmodule Web.Skill do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Effect
  alias Data.Skill
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  import Ecto.Query

  @behaviour Filter

  @doc """
  Load all skills
  """
  @spec all(Keyword.t()) :: [Skill.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Skill
    |> order_by([s], asc: s.level, asc: s.id)
    |> preload([:class])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"level_from", level}, query) do
    query |> where([s], s.level >= ^level)
  end

  def filter_on_attribute({"level_to", level}, query) do
    query |> where([s], s.level <= ^level)
  end

  def filter_on_attribute({"tag", value}, query) do
    query
    |> where([n], fragment("? @> ?::varchar[]", n.tags, [^value]))
  end

  def filter_on_attribute(_, query), do: query

  @doc """
  Get a skill
  """
  @spec get(id :: integer) :: Skill.t()
  def get(id) do
    Skill |> Repo.get(id) |> Repo.preload([:class])
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(class :: Class.t()) :: changeset :: map
  def new(class) do
    class
    |> Ecto.build_assoc(:skills)
    |> Skill.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(skill :: Skill.t()) :: changeset :: map
  def edit(skill), do: skill |> Skill.changeset(%{})

  @doc """
  Create a skill
  """
  @spec create(class :: Class.t(), params :: map) :: {:ok, Skill.t()} | {:error, changeset :: map}
  def create(class, params) do
    class
    |> Ecto.build_assoc(:skills)
    |> Skill.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a skill
  """
  @spec update(id :: integer, params :: map) :: {:ok, Skill.t()} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Skill.changeset(cast_params(params))
    |> Repo.update()
  end

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_effects()
    |> parse_tags()
  end

  defp parse_effects(params = %{"effects" => effects}) do
    case Poison.decode(effects) do
      {:ok, effects} -> effects |> cast_effects(params)
      _ -> params
    end
  end

  defp parse_effects(params), do: params

  defp cast_effects(effects, params) do
    effects =
      effects
      |> Enum.map(fn effect ->
        case Effect.load(effect) do
          {:ok, effect} -> effect
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Map.put(params, "effects", effects)
  end

  def parse_tags(params = %{"tags" => tags}) do
    tags =
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    params
    |> Map.put("tags", tags)
  end

  def parse_tags(params), do: params
end
