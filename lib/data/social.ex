defmodule Data.Social do
  @moduledoc """
  In game social commands
  """

  use Data.Schema

  schema "socials" do
    field(:name, :string)
    field(:command, :string)

    field(:with_target, :string)
    field(:without_target, :string)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :command, :with_target, :without_target])
    |> validate_required([:name, :command, :with_target, :without_target])
    |> validate_single_word_command()
  end

  defp validate_single_word_command(changeset) do
    case get_field(changeset, :command) do
      command when command != nil ->
        case length(String.split(command)) do
          1 -> changeset
          _ -> add_error(changeset, :command, "must be a single word")
        end

      _ ->
        changeset
    end
  end
end
