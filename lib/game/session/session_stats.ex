defmodule Game.Session.SessionStats do
  @moduledoc """
  Struct for session stats
  """

  @doc """
  Session stats

  - `commands`: Map of counts for command usage, The module is the key, value is the count
  """
  defstruct [commands: %{}]
end
