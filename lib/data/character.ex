defmodule Data.Character do
  @moduledoc """
  A user's character

  Should be used instead of their character as often as possible
  """

  use Data.Schema

  alias Data.Class
  alias Data.QuestProgress
  alias Data.Race
  alias Data.Save
  alias Data.User

  schema "characters" do
    field(:name, :string)
    field(:save, Save)
    field(:flags, {:array, :string})

    belongs_to(:user, User)
    belongs_to(:class, Class)
    belongs_to(:race, Race)

    has_many(:quest_progress, QuestProgress)

    timestamps()
  end

  @doc """
  Create a character struct from a user
  """
  def from_user(user) do
    character = Map.take(user, [:id, :flags, :name, :save, :class, :race])
    struct(__MODULE__, character)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :save, :flags, :race_id, :class_id])
    |> validate_required([:name, :save, :race_id, :class_id])
    |> validate_name()
    |> ensure(:flags, [])
    |> validate_save()
    |> unique_constraint(:name, name: :characters_lower_name_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:class_id)
  end

  defp validate_save(changeset) do
    case changeset do
      %{changes: %{save: save}} when save != nil ->
        _validate_save(changeset)

      _ ->
        changeset
    end
  end

  defp _validate_save(changeset = %{changes: %{save: save}}) do
    case Save.valid?(save) do
      true ->
        changeset

      false ->
        add_error(changeset, :save, "is invalid")
    end
  end

  defp validate_name(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        case Regex.match?(~r/ /, name) do
          true ->
            add_error(changeset, :name, "cannot contain spaces")

          false ->
            changeset
        end
    end
  end
end
