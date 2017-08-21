defmodule Game.Character do
  @moduledoc """
  Character GenServer client

  A character is a player (session genserver) or an NPC (genserver). They should
  handle the following casts:

  - `{:targeted, player}`
  - `{:apply_effects, effects, player}`
  """

  alias Data.User
  alias Game.Character.Via

  @spec being_targeted(who :: tuple, player :: User.t) :: :ok
  def being_targeted(target, player) do
    GenServer.cast({:via, Via, who(target)}, {:targeted, player})
  end

  @doc """
  """
  @spec apply_effects(who :: tuple, effects :: [Effect.t], from :: {atom, map}, description :: String.t) :: :ok
  def apply_effects(target, effects, from, description) do
    GenServer.cast({:via, Via, who(target)}, {:apply_effects, effects, from, description})
  end

  defp who({:npc, id}) when is_integer(id), do: {:npc, id}
  defp who({:npc, npc}), do: {:npc, npc.id}
  defp who({:user, id}) when is_integer(id), do: {:user, id}
  defp who({:user, user}), do: {:user, user.id}
end
