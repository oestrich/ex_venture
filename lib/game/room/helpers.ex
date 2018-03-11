defmodule Game.Room.Helpers do
  @moduledoc """
  Helpers for interacting with a room
  """

  alias Game.Utility

  @doc """
  Find a character in a room by name.
  """
  @spec find_character(Room.t(), String.t()) ::
          {:error, :not_found}
          | {:npc, NPC.t()}
          | {:user, User.t()}
  def find_character(room, character_name) do
    case room.players |> Enum.find(&Utility.matches?(&1, character_name)) do
      nil ->
        case room.npcs |> Enum.find(&Utility.matches?(&1, character_name)) do
          nil ->
            {:error, :not_found}

          npc ->
            {:npc, npc}
        end

      player ->
        {:user, player}
    end
  end

  @doc """
  Find a character in a room by name.
  """
  @spec find_character(Room.t(), String.t(), Keyword.t()) ::
          {:error, :not_found}
          | {:npc, NPC.t()}
          | {:user, User.t()}

  def find_character(room, who_and_message, [message: true]) do
    case room.players |> Enum.find(&Utility.name_matches?(&1, who_and_message)) do
      nil ->
        case room.npcs |> Enum.find(&Utility.name_matches?(&1, who_and_message)) do
          nil ->
            {:error, :not_found}

          npc ->
            {:npc, npc}
        end

      player ->
        {:user, player}
    end
  end
end
