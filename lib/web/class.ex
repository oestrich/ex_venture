defmodule Web.Class do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Class
  alias Data.ClassProficiency
  alias Data.ClassSkill
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all classes
  """
  @spec all(Keyword.t()) :: [Class.t()]
  def all(opts \\ [])

  def all(alpha: true) do
    Class
    |> order_by([c], c.name)
    |> Repo.all()
  end

  def all(opts) do
    opts = Enum.into(opts, %{})

    Class
    |> order_by([c], c.id)
    |> Pagination.paginate(opts)
  end

  @doc """
  List out all classs for a select box
  """
  @spec class_select() :: [{String.t(), integer()}]
  def class_select() do
    Class
    |> select([c], [c.name, c.id])
    |> order_by([c], c.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a class

  Preload skills
  """
  @spec get(integer) :: [Class.t()]
  def get(id) do
    Class
    |> where([c], c.id == ^id)
    |> preload(
      class_proficiencies:
        ^from(ca in ClassProficiency, left_join: a in assoc(ca, :proficiency), order_by: ca.level)
    )
    |> preload(
      class_skills:
        ^from(cs in ClassSkill, left_join: s in assoc(cs, :skill), order_by: [s.level, s.id])
    )
    |> preload([class_proficiencies: [:proficiency], class_skills: [:skill]])
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Class{} |> Class.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Class.t()) :: map
  def edit(class), do: class |> Class.changeset(%{})

  @doc """
  Create a class
  """
  @spec create(map) :: {:ok, Class.t()} | {:error, map}
  def create(params) do
    %Class{}
    |> Class.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update an zone
  """
  @spec update(integer, map) :: {:ok, Zone.t()} | {:error, map}
  def update(id, params) do
    id
    |> get()
    |> Class.changeset(params)
    |> Repo.update()
  end

  #
  # Class Skills
  #

  @doc """
  New changeset
  """
  @spec new_class_skill(Class.t()) :: Ecto.Changeset.t()
  def new_class_skill(class) do
    class
    |> Ecto.build_assoc(:class_skills)
    |> ClassSkill.changeset(%{})
  end

  def add_skill(class, skill_id) do
    class
    |> Ecto.build_assoc(:class_skills)
    |> ClassSkill.changeset(%{skill_id: skill_id})
    |> Repo.insert()
  end

  def remove_skill(id) do
    case Repo.get(ClassSkill, id) do
      nil -> {:error, :not_found}
      class_skill -> Repo.delete(class_skill)
    end
  end

  #
  # Class Proficiencies
  #

  @doc """
  New changeset
  """
  @spec new_class_proficiency(Class.t()) :: Ecto.Changeset.t()
  def new_class_proficiency(class) do
    class
    |> Ecto.build_assoc(:class_proficiencies)
    |> ClassProficiency.changeset(%{})
  end

  def add_proficiency(class, params) do
    class
    |> Ecto.build_assoc(:class_proficiencies)
    |> ClassProficiency.changeset(params)
    |> Repo.insert()
  end

  def remove_proficiency(id) do
    case Repo.get(ClassProficiency, id) do
      nil ->
        {:error, :not_found}

      class_proficiency ->
        Repo.delete(class_proficiency)
    end
  end
end
