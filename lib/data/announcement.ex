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
    field(:is_sticky, :boolean, default: false)
    field(:published_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:title, :body, :tags, :is_published, :is_sticky, :published_at])
    |> ensure(:published_at, Timex.now())
    |> validate_required([:title, :body, :is_published, :is_sticky, :published_at])
  end
end
