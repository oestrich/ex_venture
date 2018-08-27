defmodule Squabble.Leader do
  @moduledoc """
  Behaviour for modules that care about leader functions
  """

  @type election_term() :: integer()

  @doc """
  The local node was selected as a leader
  """
  @callback leader_selected(election_term()) :: :ok

  @doc """
  A node went down, callback from the squabble leader
  """
  @callback node_down() :: :ok
end
