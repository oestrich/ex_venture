defmodule Game.Character.State do
  @moduledoc """
  A common type for character state
  """

  alias Data.Effect
  alias Game.Character

  @type t :: %{
          continuous_effects: [{Character.t(), Effect.t()}]
        }
end
