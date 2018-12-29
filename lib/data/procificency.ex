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

    defstruct [:proficiency_id, :proficiency, :ranks]
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
