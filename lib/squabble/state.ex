defmodule Squabble.State do
  @moduledoc """
  Struct for the state of the local process
  """

  defstruct [
    :state,
    :term,
    :highest_seen_term,
    :leader_pid,
    :leader_node,
    :voted_for,
    :votes
  ]

  @doc """
  States of a node
  """
  def states() do
    ["follower", "candidate", "leader"]
  end
end
