defmodule Data.Proficiency do
  @moduledoc """
  Schema for character proficiencies
  """

  use Data.Schema

  @types ["normal"]

  defmodule Instance do
    @moduledoc """
    Struct for an proficiency in a character's save
    """

    @derive {Jason.Encoder, only: [:id, :ranks]}
    defstruct [:id, :name, :ranks]
  end

  defmodule Requirement do
    @moduledoc """
    Embedded schema for a proficiency requirement
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key {:key, :binary_id, autogenerate: true}
    embedded_schema do
      field(:id, :integer)
      field(:ranks, :integer)

      field(:name, :string, virtual: true)
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:id, :ranks])
      |> validate_required([:id, :ranks])
    end
  end

  schema "proficiencies" do
    field(:name, :string)
    field(:type, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :type])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @types)
  end
end
