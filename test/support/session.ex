defmodule Test.Session do
  @moduledoc """
  Helpers for session state
  """

  def session_state(attributes) do
    attributes = Map.merge(%{
      socket: :socket,
      state: "active",
      mode: "commands",
    }, attributes)

    attributes =
      attributes
      |> maybe_add_user()
      |> maybe_add_character()
      |> maybe_pull_out_save()

    struct(Game.Session.State, attributes)
  end

  defp maybe_add_user(attributes) do
    case Map.has_key?(attributes, :character) do
      true ->
        attributes

      false ->
        user = TestHelpers.user_attributes(%{})
        Map.put(attributes, :user, user)
    end
  end

  defp maybe_add_character(attributes) do
    case Map.has_key?(attributes, :character) do
      true ->
        attributes

      false ->
        character = TestHelpers.character_attributes(%{user: attributes.user})
        Map.put(attributes, :character, character)
    end
  end

  defp maybe_pull_out_save(attributes) do
    case Map.has_key?(attributes, :save) do
      true ->
        attributes

      false ->
        Map.put(attributes, :save, attributes.character.save)
    end
  end
end
