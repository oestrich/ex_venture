defmodule Data.NPC do
  use Data.Schema

  schema "npcs" do
    field :name
    
    belongs_to :room, Data.Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :room_id])
    |> validate_required([:name, :room_id])
  end
end
