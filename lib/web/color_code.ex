defmodule Web.ColorCode do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.ColorCode
  alias Data.Repo
  alias Game.ColorCodes
  alias Web.Color

  @doc """
  Get all bugs
  """
  @spec all() :: [ColorCode.t()]
  def all() do
    ColorCode
    |> order_by([cc], asc: cc.key)
    |> Repo.all()
  end

  @doc """
  Get a bug
  """
  @spec get(integer()) :: [ColorCode.t()]
  def get(id) do
    ColorCode
    |> where([cc], cc.id == ^id)
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %ColorCode{} |> ColorCode.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(ColorCode.t()) :: Ecto.Changeset.t()
  def edit(color_code), do: color_code |> ColorCode.changeset(%{})

  @doc """
  Create a color_code
  """
  @spec create(map()) :: {:ok, ColorCode.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    changeset = %ColorCode{} |> ColorCode.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, color_code} ->
        color_code.updated_at
        |> Timex.to_unix()
        |> Color.set_latest_version()

        color_code |> ColorCodes.insert()

        {:ok, color_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an color_code
  """
  @spec update(integer(), map()) :: {:ok, ColorCode.t()} | {:error, Ecto.Changeset.t()}
  def update(id, params) do
    color_code = id |> get()
    changeset = color_code |> ColorCode.changeset(params)

    case changeset |> Repo.update() do
      {:ok, color_code} ->
        color_code.updated_at
        |> Timex.to_unix()
        |> Color.set_latest_version()

        color_code |> ColorCodes.reload()

        {:ok, color_code}

      anything ->
        anything
    end
  end
end
