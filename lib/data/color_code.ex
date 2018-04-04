defmodule Data.ColorCode do
  @moduledoc """
  Color Code schema
  """

  use Data.Schema

  schema "color_codes" do
    field(:key, :string)
    field(:ansi_escape, :string)
    field(:hex_code, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:key, :ansi_escape, :hex_code])
    |> validate_required([:key, :ansi_escape, :hex_code])
    |> validate_format(:key, ~r/^[\w-]+$/)
    |> validate_format(:ansi_escape, ~r/^\\e\[.+m$/)
    |> validate_format(:hex_code, ~r/^#[0-9A-Fa-f]{6}$/)
    |> unique_constraint(:key)
  end
end
