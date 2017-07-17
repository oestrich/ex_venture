defmodule Data.Room do
  use Data.Schema

  schema "rooms" do
    field :name, :string
    field :description, :string

    field :players, {:array, :tuple}, virtual: true

    belongs_to :north, __MODULE__
    belongs_to :east, __MODULE__
    belongs_to :south, __MODULE__
    belongs_to :west, __MODULE__

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :north_id, :east_id, :south_id, :west_id])
    |> validate_required([:name, :description])
  end

  def exits(room) do
    ["north", "east", "south", "west"]
    |> Enum.filter(fn (direction) ->
      Map.get(room, :"#{direction}_id") != nil
    end)
  end
end
