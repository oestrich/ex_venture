defmodule Data.Config do
  use Data.Schema

  alias Data.Save

  schema "config" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :value])
    |> validate_required([:name, :value])
  end

  def starting_save() do
    save = __MODULE__
    |> where([c], c.name == "starting_save")
    |> select([c], c.value)
    |> Repo.one

    case save do
      nil -> nil
      save -> struct(Save, Poison.decode!(save))
    end
  end
end
