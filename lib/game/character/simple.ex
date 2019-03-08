defmodule Game.Character.Simple do
  @moduledoc """
  Simple version of a character

  Minimal data for accessing the full character
  """

  defstruct [:type, :id, :name, :level, extra: %{}]

  @doc """
  Convert a character into their simple version
  """
  def from_character(npc = %{type: "npc"}), do: from_npc(npc)

  def from_character(player = %{type: "player"}), do: from_player(player)

  def from_character({:npc, npc}), do: {:npc, from_npc(npc)}

  def from_character({:player, player}), do: {:player, from_player(player)}

  @doc """
  Convert a player to the simple version
  """
  def from_player(player) do
    %__MODULE__{
      type: player.type,
      id: player.id,
      name: player.name,
      level: player.save.level,
      extra: %{
        room_id: player.save.room_id,
        flags: player.flags,
        level: player.save.level,
        race: player.race.name,
        class: player.class.name
      }
    }
  end

  @doc """
  Convert an NPC to the simple version
  """
  def from_npc(npc) do
    extra =
      Map.take(npc, [
        :original_id,
        :status_line,
        :status_listen,
        :description,
        :experience_points,
        :is_quest_giver,
        :is_trainer,
        :trainable_skills
      ])

    %__MODULE__{
      type: npc.type,
      id: npc.id,
      name: npc.name,
      level: npc.level,
      extra: extra
    }
  end
end
