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
  alias Game.Character.Simple
  alias Game.Character.Via

  @typedoc """
  Tagged tuple of a player or npc struct

  Valid options:
  - `{:player, player}`
  - `{:npc, npc}`
  """
  @type t :: tuple()

  @doc """
  Convert a character into a stripped down version
  """
  def to_simple(character = %Simple{}), do: character

  def to_simple(character), do: Simple.from_character(character)

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
    GenServer.cast(
      {:via, Via, who(target)},
      {:apply_effects, effects, to_simple(from), description}
    )
  end

  @doc """
  Reply to the sending character what effects were applied
  """
  @spec effects_applied(Character.t(), [Effect.t()], Character.t()) :: :ok
  def effects_applied(from, effects, target) do
    GenServer.cast({:via, Via, who(from)}, {:effects_applied, effects, to_simple(target)})
  end

  @doc """
  Get character information about the character
  """
  @spec info(Character.t()) :: Character.t()
  def info(target) do
    GenServer.call({:via, Via, who(target)}, :info)
  end

  @doc """
  Notify a character of an event
  """
  @spec notify(Character.t(), map()) :: :ok
  def notify(target, event) do
    GenServer.cast({:via, Via, who(target)}, {:notify, event})
  end

  @doc """
  Check if a character equals another character, generaly the simple version
  """
  def equal?(nil, _target), do: false

  def equal?(_character, nil), do: false

  def equal?(character, target) do
    character.type == target.type && character.id == target.id
  end

  @doc """
  Converts a tuple with a struct to a tuple with an id
  """
  @spec who({:npc, integer()} | {:npc, NPC.t()}) :: {:npc, integer()}
  @spec who({:player, integer()} | {:player, User.t()}) :: {:player, integer()}
  def who(target)

  def who(character = %Simple{}), do: character

  def who({:npc, id}) when is_integer(id), do: {:npc, id}

  def who({:npc, npc}), do: {:npc, npc.id}

  def who({:player, id}) when is_integer(id), do: {:player, id}

  def who({:player, player}), do: {:player, player.id}
end
