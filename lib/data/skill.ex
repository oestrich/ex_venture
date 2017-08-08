defmodule Data.Skill do
  @moduledoc """
  Skill schema
  """

  use Data.Schema

  schema "skills" do
    field :name, :string
    field :description, :string
    field :command, :string
    field :effects, {:array, :string}

    belongs_to :class, Data.Class
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :command, :effects, :class_id])
    |> validate_required([:name, :description, :command, :effects, :class_id])
  end
end
