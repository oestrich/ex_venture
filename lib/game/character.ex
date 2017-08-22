defmodule Game.Character do
  @moduledoc """
  Character GenServer client

  A character is a player (session genserver) or an NPC (genserver). They should
  handle the following casts:

  - `{:targeted, player}`
  - `{:remove_target, player}`
  - `{:apply_effects, effects, player}`
  """

  alias Data.User
  alias Game.Character.Via

  @doc """
  Let the target know they are being targeted
  """
  @spec being_targeted(target :: tuple, player :: {atom, User.t}) :: :ok
  def being_targeted(target, player) do
    GenServer.cast({:via, Via, who(target)}, {:targeted, player})
  end

  @doc """
  When a player stops targetting a character, let them know
  """
  @spec remove_target(target :: tuple, player :: {atom, User.t}) :: :ok
  def remove_target(target, player) do
    GenServer.cast({:via, Via, who(target)}, {:remove_target, player})
  end

  @doc """
  """
  @spec apply_effects(who :: tuple, effects :: [Effect.t], from :: {atom, map}, description :: String.t) :: :ok
  def apply_effects(target, effects, from, description) do
    GenServer.cast({:via, Via, who(target)}, {:apply_effects, effects, from, description})
  end

  @doc """
  Converts a tuple with a struct to a tuple with an id
  """
  def who({:npc, id}) when is_integer(id), do: {:npc, id}
  def who({:npc, npc}), do: {:npc, npc.id}
  def who({:user, id}) when is_integer(id), do: {:user, id}
  def who({:user, user}), do: {:user, user.id}
end
