defmodule Raft.State do
  @moduledoc """
  Struct for the state of the local process
  """

  defstruct [:state, :term, :leader_pid, :votes]

  @doc """
  States of a node
  """
  def states() do
    ["follower", "candidate", "leader"]
  end
end
