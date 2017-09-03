defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Stats
  alias Data.ZoneNPC

  schema "npcs" do
    field :name, :string
    field :hostile, :boolean
    field :level, :integer
    field :experience_points, :integer # given after defeat
    field :stats, Data.Stats

    has_many :zone_npcs, ZoneNPC

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :hostile, :level, :experience_points, :stats])
    |> validate_required([:name, :hostile, :level, :experience_points, :stats])
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
