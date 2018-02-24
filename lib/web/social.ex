defmodule Web.Social do
  @moduledoc """
  Context to the social schema
  """

  alias Data.Social
  alias Data.Repo
  alias Game.Socials
  alias Web.Filter
  alias Web.Pagination

  import Ecto.Changeset, only: [get_change: 2]
  import Ecto.Query

  @behaviour Filter

  @doc """
  Load all socials
  """
  @spec all(Keyword.t()) :: [Skill.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Social
    |> order_by([s], asc: s.command)
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"name", value}, query) do
    query |> where([s], ilike(s.name, ^"%#{value}%"))
  end

  def filter_on_attribute(_, query), do: query

  @doc """
  Get a social command
  """
  @spec get(integer()) :: Social.t()
  def get(id), do: Repo.get(Social, id)

  @doc """
  New changeset
  """
  def new(), do: %Social{} |> Social.changeset(%{})

  @doc """
  Edit changeset
  """
  def edit(social), do: social |> Social.changeset(%{})

  @doc """
  Create a new social command
  """
  @spec create(map()) :: {:ok, Social.t()}
  def create(params) do
    changeset = %Social{} |> Social.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, social} ->
        Socials.insert(social)
        {:ok, social}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a social command
  """
  @spec update(Social.t(), map()) :: {:ok, Social.t()}
  def update(social, params) do
    changeset = social |> Social.changeset(params)
    original_command = social.command

    case changeset |> Repo.update() do
      {:ok, social} ->
        maybe_remove_old_command(original_command, changeset)
        Socials.reload(social)
        {:ok, social}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp maybe_remove_old_command(command, changeset) do
    case get_change(changeset, :command) do
      nil ->
        :ok

      _ ->
        Socials.remove_command(command)
    end
  end
end
