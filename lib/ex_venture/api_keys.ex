defmodule ExVenture.APIKeys.APIKey do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  schema "api_keys" do
    field(:token, Ecto.UUID, autogenerate: true)
    field(:is_active, :boolean, default: true)

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:token, :is_active])
    |> unique_constraint(:token)
  end
end

defmodule ExVenture.APIKeys do
  @moduledoc """
  API Keys to lock down the API
  """

  alias ExVenture.APIKeys.APIKey
  alias ExVenture.Repo

  @doc """
  Create a new API key
  """
  def create(params \\ %{}) do
    %APIKey{}
    |> APIKey.create_changeset(params)
    |> Repo.insert()
  end

  def valid?(token) do
    case Repo.get_by(APIKey, token: token) do
      nil ->
        false

      api_key ->
        api_key.is_active
    end
  end
end
