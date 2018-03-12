defmodule Data.Announcement do
  @moduledoc """
  A game announcement schema
  """

  use Data.Schema

  schema "announcements" do
    field(:is_published, :boolean, default: false)
    field(:title, :string)
    field(:body, :string)
    field(:tags, {:array, :string}, default: [])
    field(:uuid, Ecto.UUID, read_on_write: true)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :body, :tags, :is_published])
    |> validate_required([:title, :body, :is_published])
  end
end
