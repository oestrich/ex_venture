defmodule Data.Announcement do
  @moduledoc """
  A game announcement schema
  """

  use Data.Schema

  schema "announcements" do
    field(:title, :string)
    field(:body, :string)
    field(:tags, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :body, :tags])
    |> validate_required([:title, :body])
  end
end
