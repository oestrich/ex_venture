defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Stats

  schema "npcs" do
    field :name, :string
    field :hostile, :boolean
    field :level, :integer
    field :experience_points, :integer # given after defeat
    field :stats, Data.Stats
    field :spawn_interval, :integer
    
    belongs_to :room, Data.Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :room_id, :hostile, :level, :experience_points, :stats, :spawn_interval])
    |> validate_required([:name, :room_id, :hostile, :level, :experience_points, :stats, :spawn_interval])
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
