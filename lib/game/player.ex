defmodule Game.Player do
  @moduledoc """
  Update a user's data in their session
  """

  @doc """
  Update the player's save in the session struct
  """
  def update_save(state, save) do
    character = %{state.character | save: save}
    %{state | character: character, save: save}
  end
end
