defmodule Data.ZoneNPC do
  @moduledoc """
  Schema for Zone NPC connections
  """

  use Data.Schema

  alias Data.NPC
  alias Data.Room
  alias Data.Zone

  schema "zone_npcs" do
    field :spawn_interval, :integer

    belongs_to :zone, Zone
    belongs_to :npc, NPC
    belongs_to :room, Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:zone_id, :npc_id, :room_id, :spawn_interval])
    |> validate_required([:zone_id, :npc_id, :room_id, :spawn_interval])
    |> foreign_key_constraint(:zone_id)
    |> foreign_key_constraint(:npc_id)
    |> foreign_key_constraint(:room_id)
  end
end
