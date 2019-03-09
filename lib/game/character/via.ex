defmodule Game.Character.Via do
  @moduledoc """
  Send to either a player (session) or an NPC
  """

  alias Game.Session

  @doc """
  Find the player or NPC pid

  Callback for :via GenServer lookup
  """
  @spec whereis_name(any) :: pid
  def whereis_name(who)

  def whereis_name(%{type: "npc", id: id}) do
    :global.whereis_name({Game.NPC, id})
  end

  def whereis_name(%{type: "player", id: id}) do
    case Session.Registry.find_connected_player(id) do
      %{pid: pid} ->
        pid

      _ ->
        :undefined
    end
  end

  @doc """
  Callback for :via GenServer lookup
  """
  @spec send(any, any) :: :ok
  def send(who, message)

  def send(%{type: "npc", id: id}, message) do
    :global.send({Game.NPC, id}, message)
  end

  def send(character = %{type: "player"}, message) do
    case whereis_name(character) do
      :undefined ->
        {:badarg, {character, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end
end
