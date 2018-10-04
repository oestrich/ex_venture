defmodule Test.Session do
  @moduledoc """
  Helpers for session state
  """

  alias Data.Character

  def session_state(attributes) do
    attributes = Map.merge(%{
      socket: :socket,
      state: "active",
      mode: "commands",
    }, attributes)

    attributes =
      attributes
      |> maybe_characterize()
      |> maybe_pull_out_save()

    struct(Game.Session.State, attributes)
  end

  defp maybe_pull_out_save(attributes) do
    case Map.has_key?(attributes, :save) do
      true ->
        attributes

      false ->
        Map.put(attributes, :save, attributes.user.save)
    end
  end

  defp maybe_characterize(attributes) do
    case Map.has_key?(attributes, :character) do
      true ->
        attributes

      false ->
        Map.put(attributes, :character, Character.from_user(attributes.user))
    end
  end
end
