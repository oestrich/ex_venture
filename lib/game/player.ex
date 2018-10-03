defmodule Game.Player do
  @moduledoc """
  Update a user's data in their session
  """

  @doc """
  Update the player's save in the session struct
  """
  def update_save(state, save) do
    player = %{state.user | save: save}
    %{state | user: player, save: save}
  end
end
