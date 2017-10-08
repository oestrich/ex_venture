defmodule Data.Item do
  @moduledoc """
  Item Schema
  """

  use Data.Schema

  alias Data.Effect
  alias Data.Stats

  @types ["basic", "weapon", "armor"]

  @valid_effects %{
    "basic" => [],
    "weapon" => ["damage", "stats"],
    "armor" => ["stats"],
  }

  schema "items" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :keywords, {:array, :string}
    field :stats, Data.Stats
    field :effects, {:array, Data.Effect}
    field :drop_rate, :integer
    field :cost, :integer, default: 0

    timestamps()
  end

  @doc """
  List out item types
  """
  @spec types() :: [String.t]
  def types(), do: @types

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :type, :keywords, :stats, :effects, :drop_rate, :cost])
    |> ensure_keywords
    |> validate_required([:name, :description, :type, :keywords, :stats, :effects, :drop_rate, :cost])
    |> validate_inclusion(:type, @types)
    |> validate_stats()
    |> Effect.validate_effects()
    |> validate_effects()
  end

  defp ensure_keywords(changeset) do
    case changeset do
      %{changes: %{keywords: _keywords}} -> changeset
      %{data: %{keywords: keywords}} when keywords != nil -> changeset
      _ -> put_change(changeset, :keywords, [])
    end
  end

  defp validate_stats(changeset) do
    case changeset do
      %{changes: %{stats: stats}} when stats != nil ->
        _validate_stats(changeset)
      _ -> changeset
    end
  end

  defp _validate_stats(changeset = %{changes: %{stats: stats}}) do
    type = type_from_changeset(changeset)
    case Stats.valid?(type, stats) do
      true -> changeset
      false -> add_error(changeset, :stats, "are invalid")
    end
  end

  defp type_from_changeset(%{changes: %{type: type}}) when type != nil, do: type
  defp type_from_changeset(%{data: %{type: type}}), do: type

  defp validate_effects(changeset) do
    case changeset do
      %{changes: %{effects: effects}} when effects != nil ->
        _validate_effects(changeset)
      _ -> changeset
    end
  end

  defp _validate_effects(changeset = %{changes: %{effects: effects}}) do
    type = type_from_changeset(changeset)
    case effects |> Enum.all?(&(&1.kind in @valid_effects[type])) do
      true -> changeset
      false -> add_error(changeset, :effects, "can only include damage or stats effects")
    end
  end
end
