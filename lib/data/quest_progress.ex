defmodule Data.QuestProgress do
  @moduledoc """
  Quest Progress schema
  """

  use Data.Schema

  alias Data.Quest
  alias Data.User

  @statuses ["active"]

  schema "quest_progress" do
    field :status, :string, default: "active"
    field :progress, :map, default: %{}

    belongs_to :quest, Quest
    belongs_to :user, User

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:status, :progress, :user_id, :quest_id])
    |> validate_required([:status, :progress, :user_id, :quest_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
    |> unique_constraint(:quest_id, name: :quest_progress_user_id_quest_id_index)
  end
end
