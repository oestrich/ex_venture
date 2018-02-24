defmodule Data.Channel do
  @moduledoc """
  In game communication channel schema
  """

  use Data.Schema

  alias Game.Color

  schema "channels" do
    field(:name, :string)
    field(:color, :string, default: "red")

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :color])
    |> validate_required([:name, :color])
    |> validate_inclusion(:color, Color.options())
    |> validate_single_word_name()
  end

  defp validate_single_word_name(changeset) do
    case get_field(changeset, :name) do
      name when name != nil ->
        case length(String.split(name)) do
          1 -> changeset
          _ -> add_error(changeset, :name, "must be a single word")
        end

      _ ->
        changeset
    end
  end
end
