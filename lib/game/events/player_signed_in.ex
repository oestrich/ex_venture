defmodule Game.Events.PlayerSignedIn do
  @moduledoc """
  Event for players signing in
  """

  defstruct [:character, type: "player/signed_in"]
end
