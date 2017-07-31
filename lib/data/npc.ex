defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  schema "npcs" do
    field :name, :string
    field :hostile, :boolean
    
    belongs_to :room, Data.Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :room_id, :hostile])
    |> validate_required([:name, :room_id, :hostile])
  end
end
