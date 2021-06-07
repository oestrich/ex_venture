defmodule ExVenture.Characters.PlayableCharacter do
  @moduledoc """
  Schema for a character controlled by a player
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Characters.Character
  alias ExVenture.Users.User

  schema "playable_characters" do
    belongs_to(:character, Character)
    belongs_to(:user, User)

    timestamps()
  end

  def create_changeset(struct, character) do
    struct
    |> change()
    |> put_change(:character_id, character.id)
    |> validate_required([:character_id, :user_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:user_id)
  end
end
