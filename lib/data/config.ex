defmodule Data.Config do
  @moduledoc """
  Config Schema
  """

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
      save ->
        {:ok, save} = Save.load(Poison.decode!(save))
        save
    end
  end

  def find_config(name) do
    __MODULE__
    |> where([c], c.name == ^name)
    |> select([c], c.value)
    |> Repo.one
  end
end
