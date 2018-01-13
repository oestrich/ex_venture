defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Conversation
  alias Data.Event
  alias Data.Stats
  alias Data.NPCItem
  alias Data.NPCSpawner

  schema "npcs" do
    field :name, :string
    field :level, :integer, default: 1
    field :experience_points, :integer, default: 0 # given after defeat
    field :stats, Data.Stats
    field :events, {:array, Event}
    field :conversations, {:array, Conversation}
    field :notes, :string
    field :tags, {:array, :string}, default: []
    field :status_line, :string, default: "{name} is here."
    field :description, :string, default: "{status_line}"

    field :currency, :integer, default: 0

    has_many :npc_items, NPCItem
    has_many :npc_spawners, NPCSpawner

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :level, :experience_points, :stats, :currency, :notes, :tags, :events, :conversations, :status_line, :description])
    |> validate_required([:name, :level, :experience_points, :stats, :currency, :tags, :events, :status_line, :description])
    |> validate_stats()
    |> Event.validate_events()
    |> Conversation.validate_conversations()
    |> validate_status_line()
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
    case Regex.match?(~r/{name}/, get_field(changeset, :status_line)) do
      true -> changeset
      false -> add_error(changeset, :status_line, "must include `{name}`")
    end
  end
end
