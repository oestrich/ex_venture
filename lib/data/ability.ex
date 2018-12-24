defmodule Data.Ability do
  @moduledoc """
  Schema for character abilities
  """

  use Data.Schema

  @types ["normal"]

  schema "abilities" do
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
