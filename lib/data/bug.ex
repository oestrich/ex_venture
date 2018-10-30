defmodule Data.Bug do
  @moduledoc """
  Bug schema
  """

  use Data.Schema

  alias Data.Character

  schema "bugs" do
    field(:title, :string)
    field(:body, :string)
    field(:is_completed, :boolean, default: false)

    belongs_to(:reporter, Character)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :body, :reporter_id])
    |> validate_required([:title, :reporter_id])
    |> foreign_key_constraint(:reporter_id)
  end

  def completed_changeset(struct, params) do
    struct
    |> cast(params, [:is_completed])
    |> validate_required([:is_completed])
  end
end
