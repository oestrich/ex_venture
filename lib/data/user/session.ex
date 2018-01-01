defmodule Data.User.Session do
  @moduledoc """
  Schema for a session, track statistics about it
  """

  use Data.Schema

  alias Data.User

  schema "sessions" do
    field :started_at, Timex.Ecto.DateTime
    field :seconds_online, :integer

    belongs_to :user, User

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:started_at, :seconds_online, :user_id])
    |> validate_required([:started_at, :seconds_online, :user_id])
  end
end
