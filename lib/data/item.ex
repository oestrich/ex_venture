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
    |> validate_required([:name, :description, :keywords])
  end
end
