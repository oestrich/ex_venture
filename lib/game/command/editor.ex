defmodule Game.Command.Editor do
  @moduledoc """
  Editor callback

  If a command requires an editor, it should `use` this module and follow the callbacks.
  """

  @callback editor({:text, String.t()}, state :: map) :: {:update, state :: map}
  @callback editor(:complete, state :: map) :: {:update, state :: map}

  defmacro __using__(_opts) do
    quote do
      @behaviour Game.Command.Editor
    end
  end
end
