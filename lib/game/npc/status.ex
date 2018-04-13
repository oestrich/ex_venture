defmodule Game.NPC.Status do
  @moduledoc """
  Structure for NPC status
  """

  @doc """
  - `key`: Key for the status. The starting status is "start"
  - `line`: text used for the status line, showed to players in the room look
  - `listen`: text used for when a player listens to the room they're in
  """
  defstruct [:key, :line, :listen]
end
