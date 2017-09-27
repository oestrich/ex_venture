defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.Stats
  alias Data.NPCSpawner

  schema "npcs" do
    field :name, :string
    field :hostile, :boolean
    field :level, :integer
    field :experience_points, :integer # given after defeat
    field :stats, Data.Stats
    field :notes

    field :currency, :integer
    field :item_ids, {:array, :integer}
    field :items, {:array, Item}, virtual: true

    has_many :npc_spawners, NPCSpawner

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :hostile, :level, :experience_points, :stats, :currency, :item_ids, :notes])
    |> ensure(:item_ids, [])
    |> validate_required([:name, :hostile, :level, :experience_points, :stats, :currency, :item_ids])
    |> validate_stats()
  end

  defp validate_stats(changeset) do
    case changeset do
      %{changes: %{stats: stats}} when stats != nil ->
        case Stats.valid_character?(stats) do
          true -> changeset
          false -> add_error(changeset, :stats, "are invalid")
        end
      _ -> changeset
    end
  end
end
