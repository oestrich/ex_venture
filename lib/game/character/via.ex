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

  def whereis_name({:npc, id}) do
    :global.whereis_name({Game.NPC, id})
  end

  def whereis_name({:player, id}) do
    player =
      Session.Registry.connected_players()
      |> Enum.find(&(&1.player.id == id))

    case player do
      %{pid: pid} -> pid
      _ -> :undefined
    end
  end

  @doc """
  Callback for :via GenServer lookup
  """
  @spec send(any, any) :: :ok
  def send(who, message)

  def send({:npc, id}, message) do
    :global.send({Game.NPC, id}, message)
  end

  def send({:player, id}, message) do
    case whereis_name({:player, id}) do
      :undefined ->
        {:badarg, {{:player, id}, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end
end
