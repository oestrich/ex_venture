defmodule Data.Bug do
  @moduledoc """
  Bug schema
  """

  use Data.Schema

  alias Data.User

  schema "bugs" do
    field :title, :string
    field :body, :string

    belongs_to :reporter, User

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :body, :reporter_id])
    |> validate_required([:title, :reporter_id])
    |> foreign_key_constraint(:reporter_id)
  end
end
