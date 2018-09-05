defmodule Game.Command.ParseContext do
  @moduledoc """
  A context struct for command parsing.
  """

  @type t :: %__MODULE__{}

  defstruct [:player]
end
