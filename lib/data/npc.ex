defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Script
  alias Data.Event
  alias Data.Stats
  alias Data.NPCItem
  alias Data.NPCSpawner

  @fields [
    :level,
    :name,
    :tags,
    :status_line,
    :description,
    :experience_points,
    :currency,
    :is_quest_giver,
    :is_trainer,
    :stats,
    :events,
    :script,
    :notes
  ]

  schema "npcs" do
    field(:original_id, :integer, virtual: true)
    field(:name, :string)
    field(:level, :integer, default: 1)
    # given after defeat
    field(:experience_points, :integer, default: 0)
    field(:stats, Data.Stats)
    field(:events, {:array, Event})
    field(:script, {:array, Script.Line})
    field(:notes, :string)
    field(:tags, {:array, :string}, default: [])
    field(:status_line, :string, default: "[name] is here.")
    field(:description, :string, default: "[status_line]")
    field(:is_quest_giver, :boolean, default: false)

    field(:is_trainer, :boolean, default: false)
    field(:trainable_skills, {:array, :integer}, default: [])

    field(:currency, :integer, default: 0)

    has_many(:npc_items, NPCItem)
    has_many(:npc_spawners, NPCSpawner)

    timestamps()
  end

  @doc """
  Get fields for an NPC, used for cloning.
  """
  @spec fields() :: [atom()]
  def fields(), do: @fields

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :level,
      :experience_points,
      :stats,
      :currency,
      :notes,
      :tags,
      :events,
      :script,
      :status_line,
      :description,
      :is_quest_giver,
      :is_trainer
    ])
    |> validate_required([
      :name,
      :level,
      :experience_points,
      :stats,
      :currency,
      :tags,
      :events,
      :status_line,
      :description,
      :is_quest_giver,
      :is_trainer
    ])
    |> validate_stats()
    |> Event.validate_events()
    |> Script.validate_script()
    |> validate_script()
    |> validate_status_line()
  end

  def trainable_skills_changeset(struct, params) do
    struct
    |> cast(params, [:trainable_skills])
    |> validate_required([:trainable_skills])
    |> validate_is_trainer()
  end

  defp validate_stats(changeset) do
    case changeset do
      %{changes: %{stats: stats}} when stats != nil ->
        case Stats.valid_character?(stats) do
          true -> changeset
          false -> add_error(changeset, :stats, "are invalid")
        end

      _ ->
        changeset
    end
  end

  defp validate_status_line(changeset) do
    changeset
    |> validate_status_line_ends_in_period()
    |> validate_status_line_includes_name()
  end

  defp validate_status_line_ends_in_period(changeset) do
    case Regex.match?(~r/\.$/, get_field(changeset, :status_line)) do
      true -> changeset
      false -> add_error(changeset, :status_line, "must end with a period.")
    end
  end

  defp validate_status_line_includes_name(changeset) do
    case Regex.match?(~r/[name]/, get_field(changeset, :status_line)) do
      true -> changeset
      false -> add_error(changeset, :status_line, "must include `[name]`")
    end
  end

  defp validate_script(changeset) do
    case get_field(changeset, :script) do
      nil -> changeset
      script -> _validate_script(changeset, script)
    end
  end

  defp _validate_script(changeset, script) do
    case Script.valid_for_npc?(script) do
      true ->
        changeset

      false ->
        add_error(
          changeset,
          :script,
          "cannot include a conversation that has a trigger with quest"
        )
    end
  end

  defp validate_is_trainer(changeset) do
    case get_field(changeset, :is_trainer) do
      true -> changeset
      false -> add_error(changeset, :trainable_skills, "not a trainer")
    end
  end
end
