defmodule Data.Skill do
  @moduledoc """
  Skill schema
  """

  use Data.Schema

  import Data.Effect, only: [validate_effects: 1]

  schema "skills" do
    field :name, :string
    field :description, :string
    field :user_text, :string
    field :usee_text, :string
    field :command, :string
    field :effects, {:array, Data.Effect}

    belongs_to :class, Data.Class
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :user_text, :usee_text, :command, :effects, :class_id])
    |> validate_required([:name, :description, :user_text, :usee_text, :command, :effects, :class_id])
    |> validate_effects()
  end
end
