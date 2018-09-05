defmodule Game.Character.Simple do
  @moduledoc """
  Simple version of a character

  Minimal data for accessing the full character
  """

  defstruct [:type, :id, :name, extra: %{}]

  @doc """
  Convert a character into their simple version
  """
  def from_character({:npc, npc}), do: {:npc, from_npc(npc)}
  def from_character({:player, player}), do: {:player, from_player(player)}

  @doc """
  Convert a player to the simple version
  """
  def from_player(player) do
    %__MODULE__{
      type: :player,
      id: player.id,
      name: player.name,
      extra: %{
        room_id: player.save.room_id,
        flags: player.flags,
        level: player.save.level,
        race: player.race.name,
        class: player.class.name,
      }
    }
  end

  @doc """
  Convert an NPC to the simple version
  """
  def from_npc(npc) do
    %__MODULE__{
      type: :npc,
      id: npc.id,
      name: npc.name,
      extra: %{
        original_id: npc.original_id,
        status_line: npc.status_line,
        description: npc.description,
        is_quest_giver: npc.is_quest_giver,
        is_trainer: npc.is_trainer,
        trainable_skills: npc.trainable_skills,
      }
    }
  end
end
