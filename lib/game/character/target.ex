defmodule Game.Character.Target do
  @moduledoc """
  Helper module for dealing with targets
  """

  alias Game.Character
  alias Game.Session.GMCP

  @doc """
  """
  @spec clear_target(state :: map, who :: {atom, map}) :: :ok
  def clear_target(state, who)
  def clear_target(state = %{target: target}, who) when target != nil do
    state |> GMCP.clear_target()
    Character.remove_target(target, who)
  end
  def clear_target(_state, _who), do: :ok
end
