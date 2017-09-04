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
    |> validate_room_in_zone()
    |> foreign_key_constraint(:zone_id)
    |> foreign_key_constraint(:npc_id)
    |> foreign_key_constraint(:room_id)
  end

  defp validate_room_in_zone(changeset) do
    case changeset.changes do
      %{room_id: room_id} ->
        room = Repo.get(Room, room_id)
        zone_id = get_field(changeset, :zone_id)
        case room.zone_id == zone_id do
          true -> changeset
          false -> add_error(changeset, :room_id, "must be in the same zone")
        end
      _ -> changeset
    end
  end
end
