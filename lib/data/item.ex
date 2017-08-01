defmodule Data.Item do
  @moduledoc """
  Item Schema
  """

  use Data.Schema

  alias Data.Stats

  @type t :: %{
    name: String.t,
    description: String.t,
    type: String.t,
    stats: Stats.weapon | Stats.armor,
  }

  @types ["basic", "weapon", "armor"]

  schema "items" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :keywords, {:array, :string}
    field :stats, Data.Stats

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :type, :keywords, :stats])
    |> ensure_keywords
    |> validate_required([:name, :description, :type, :keywords, :stats])
    |> validate_inclusion(:type, @types)
    |> validate_stats()
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
end
