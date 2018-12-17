defmodule Game.Format.NPCs do
  @moduledoc """
  Format functions for npcs
  """

  import Game.Format.Context

  alias Game.Format

  @doc """
  Colorize an npc's name
  """
  @spec npc_name(NPC.t()) :: String.t()
  def npc_name(npc) do
    context()
    |> assign(:name, npc.name)
    |> Format.template("{npc}[name]{/npc}")
  end

  @doc """
  The status of an NPC
  """
  def npc_status(npc) do
    context()
    |> assign(:name, npc_name_for_status(npc))
    |> Format.template(npc.extra.status_line)
  end

  @doc """
  Look at an NPC
  """
  @spec npc_full(Npc.t()) :: String.t()
  def npc_full(npc) do
    context()
    |> assign(:name, npc_name(npc))
    |> assign(:status_line, npc_status(npc))
    |> Format.template(Format.resources(npc.extra.description))
  end

  @doc """
  Display the NPC name for the status line

  Includes an `!` if the NPC is a quest giver
  """
  def npc_name_for_status(npc) do
    case Map.get(npc.extra, :is_quest_giver, false) do
      true ->
        context()
        |> assign(:name, npc_name(npc))
        |> Format.template("[name] ({quest}!{/quest})")

      false ->
        npc_name(npc)
    end
  end
end
