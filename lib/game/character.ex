defmodule Game.Character do
  @moduledoc """
  Character GenServer client

  A character is a player (session genserver) or an NPC (genserver). They should
  handle the following casts:

  - `{:targeted, player}`
  - `{:apply_effects, effects, player}`
  """

  alias Data.NPC
  alias Data.User
  alias Game.Character.Via

  @typedoc """
  Tagged tuple of a user or npc struct

  Valid options:
  - `{:user, user}`
  - `{:npc, npc}`
  """
  @type t :: tuple()

  @doc """
  Let the target know they are being targeted
  """
  @spec being_targeted(tuple(), Character.t()) :: :ok
  def being_targeted(target, player) do
    GenServer.cast({:via, Via, who(target)}, {:targeted, player})
  end

  @doc """
  Apply effects on the target
  """
  @spec apply_effects(tuple(), [Effect.t()], Character.t(), String.t()) :: :ok
  def apply_effects(target, effects, from, description) do
    GenServer.cast({:via, Via, who(target)}, {:apply_effects, effects, from, description})
  end

  @doc """
  Get character information about the character
  """
  @spec info(Character.t()) :: Character.t()
  def info(target) do
    GenServer.call({:via, Via, who(target)}, :info)
  end

  @doc """
  Converts a tuple with a struct to a tuple with an id
  """
  @spec who({:npc, integer()} | {:npc, NPC.t()}) :: {:npc, integer()}
  @spec who({:user, integer()} | {:user, User.t()}) :: {:user, integer()}
  def who(target)
  def who({:npc, id}) when is_integer(id), do: {:npc, id}
  def who({:npc, npc}), do: {:npc, npc.id}
  def who({:user, id}) when is_integer(id), do: {:user, id}
  def who({:user, user}), do: {:user, user.id}
end
