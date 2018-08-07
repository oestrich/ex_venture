defmodule Raft.Leader do
  @moduledoc """
  Behaviour for modules that care about leader functions
  """

  @doc """
  The local node was selected as a leader
  """
  @callback leader_selected() :: :ok

  @doc """
  A node went down, callback from the raft leader
  """
  @callback node_down() :: :ok
end
