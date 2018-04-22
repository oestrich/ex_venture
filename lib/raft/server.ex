defmodule Raft.Server do
  @moduledoc """
  Implementation for the raft server
  """

  alias Raft.PG

  require Logger

  @doc """
  Try to elect yourself as the leader
  """
  def start_election(state, term) do
    Logger.debug(fn ->
      "Starting an election for term #{term}, announcing candidacy"
    end)

    case term <= state.term do
      true ->
        Logger.debug(fn ->
          "Someone already won this round, not starting"
        end)

      false ->
        PG.broadcast([others: true], fn pid ->
          Raft.announce_candidate(pid, term)
        end)
    end

    {:ok, state}
  end

  @doc """
  Vote for the leader

  TODO: check for term is newer
  """
  def vote_leader(state, pid, term) do
    Logger.debug(fn ->
      "Received ballot for term #{term}, from #{inspect(pid)}, voting"
    end)

    Raft.vote_for(pid, term)

    {:ok, state}
  end

  @doc """
  A vote came in from the cluster

  TODO: check for term is newer
  TODO: ensure majority of votes are in
  """
  def new_vote(state, pid, term) do
    Logger.debug(fn ->
      "Received a vote for leader for term #{term}, from #{inspect(pid)}"
    end)

    Raft.new_leader(pid, term)

    {:ok, state}
  end

  @doc """
  Set the winner as leader

  TODO: check for term is newer
  """
  def set_leader(state, pid, term) do
    Logger.debug(fn ->
      "Setting leader for term #{term} as #{inspect(pid)}"
    end)

    {:ok, %{state | term: term, leader_pid: pid}}
  end
end
