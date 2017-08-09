defmodule Game.Character do
  @moduledoc """
  Character GenServer client

  A character is a player (session genserver) or an NPC (genserver). They should
  handle the following casts:
  
  - `{:targeted, player}`
  """

  alias Data.User
  alias Game.Character.Via

  @spec being_targeted(who :: tuple, player :: User.t) :: :ok
  def being_targeted(who, player) do
    GenServer.cast({:via, Via, who}, {:targeted, player})
  end
end
