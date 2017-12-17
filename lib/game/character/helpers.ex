defmodule Game.Character.Helpers do
  @moduledoc """
  Character helper module, common character functions
  """

  use Game.Room

  alias Game.Character
  alias Game.Session
  alias Game.Session.GMCP

  @doc """
  If the state has a target, send the target a removal message.
  """
  @spec clear_target(state :: Session.t(), who :: {atom, map}) :: :ok
  def clear_target(state, who)
  def clear_target(%{target: target}, who = {:npc, _}) when target != nil do
    Character.remove_target(target, who)
  end
  def clear_target(state = %{target: target}, who) when target != nil do
    state |> GMCP.clear_target()
    Character.remove_target(target, who)
  end
  def clear_target(_state, _who), do: :ok

  @doc """
  Update a character's stats in the room
  """
  @spec update_character(room_id :: integer, user :: User.t) :: :ok
  def update_character(room_id, user) do
    room_id |> @room.update_character({:user, self(), user})
  end
end
