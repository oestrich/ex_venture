defmodule Data.Quest do
  @moduledoc """
  Quest schema
  """

  use Data.Schema

  alias Data.NPC

  schema "quests" do
    field :name, :string
    field :description, :string
    field :level, :integer

    belongs_to :giver, NPC

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :level, :giver_id])
    |> validate_required([:name, :description, :level, :giver_id])
    |> foreign_key_constraint(:giver_id)
  end
end
