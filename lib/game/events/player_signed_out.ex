defmodule Game.Events.PlayerSignedOut do
  @moduledoc """
  Event for players signing out
  """

  defstruct [:character, type: "player/signed_out"]
end
