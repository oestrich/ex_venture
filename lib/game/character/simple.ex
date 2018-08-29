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
  def from_character({:user, user}), do: {:user, from_user(user)}

  @doc """
  Convert a user to the simple version
  """
  def from_user(user) do
    %__MODULE__{
      type: :user,
      id: user.id,
      name: user.name,
      extra: %{
        room_id: user.save.room_id,
        flags: user.flags,
        level: user.save.level,
        race: user.race.name,
        class: user.class.name,
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
      }
    }
  end
end
