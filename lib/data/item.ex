defmodule Data.Item do
  use Data.Schema

  @type t :: %{
    name: String.t,
    description: String.t,
  }

  schema "items" do
    field :name, :string
    field :description, :string
    field :keywords, {:array, :string}

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :keywords])
    |> ensure_keywords
    |> validate_required([:name, :description, :keywords])
  end

  defp ensure_keywords(changeset) do
    case changeset do
      %{changeset: %{keywords: _keywords}} -> changeset
      %{data: %{keywords: keywords}} when keywords != nil -> changeset
      _ -> put_change(changeset, :keywords, [])
    end
  end
end
