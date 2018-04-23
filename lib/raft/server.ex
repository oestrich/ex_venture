defmodule Raft.Server do
  @moduledoc """
  Implementation for the raft server
  """

  alias Raft.PG

  require Logger

  def look_for_leader(state) do
    Logger.debug("Checking for a current leader.")

    PG.broadcast([others: true], fn pid ->
      Raft.leader_check(pid)
    end)

    {:ok, state}
  end

  def leader_check(state, pid) do
    case state.state do
      "leader" ->
        Raft.notify_of_leader(pid, state.term)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  @doc """
  Try to elect yourself as the leader
  """
  def start_election(state, term) do
    Logger.debug(fn ->
      "Starting an election for term #{term}, announcing candidacy"
    end)

    case check_term_newer(state, term) do
      {:ok, :newer} ->
        PG.broadcast([others: true], fn pid ->
          Raft.announce_candidate(pid, term)
        end)

        {:ok, %{state | highest_seen_term: term}}

      {:error, :older} ->
        Logger.debug(fn ->
          "Someone already won this round, not starting"
        end)

        {:ok, state}
    end
  end

  @doc """
  Vote for the leader
  """
  def vote_leader(state, pid, term) do
    Logger.debug(fn ->
      "Received ballot for term #{term}, from #{inspect(pid)}, voting"
    end)

    with {:ok, :newer} <- check_term_newer(state, term),
         {:ok, :not_voted} <- check_voted(state) do
      Raft.vote_for(pid, term)
      {:ok, %{state | voted_for: pid, highest_seen_term: term}}
    else
      _ ->
        {:ok, state}
    end
  end

  @doc """
  A vote came in from the cluster
  """
  def vote_received(state, pid, term) do
    Logger.debug(fn ->
      "Received a vote for leader for term #{term}, from #{inspect(pid)}"
    end)

    with {:ok, :newer} <- check_term_newer(state, term),
         {:ok, state} <- append_vote(state, pid),
         {:ok, :majority} <- check_majority_votes(state) do

      Logger.debug(fn ->
        "Won the election for term #{term}"
      end)

      PG.broadcast([others: true], fn pid ->
        Raft.new_leader(pid, term)
      end)

      {:ok, state} = set_leader(state, self(), term)
      {:ok, %{state | state: "leader"}}
    else
      {:error, :older} ->
        Logger.debug("An old vote received - ignoring")

        {:ok, state}

      {:error, :not_enough} ->
        Logger.debug("Not enough votes to be a winner")

        append_vote(state, pid)
    end
  end

  @doc """
  Set the winner as leader

  TODO: check for term is newer
  """
  def set_leader(state, pid, term) do
    Logger.debug(fn ->
      "Setting leader for term #{term} as #{inspect(pid)}"
    end)

    state =
      state
      |> Map.put(:term, term)
      |> Map.put(:highest_seen_term, term)
      |> Map.put(:leader_pid, pid)
      |> Map.put(:state, "follower")
      |> Map.put(:votes, [])
      |> Map.put(:voted_for, nil)

    {:ok, state}
  end

  @doc """
  Check if a term is newer than the local state
  """
  @spec check_term_newer(State.t(), integer()) :: boolean()
  def check_term_newer(state, term) do
    case term > state.term do
      true ->
        {:ok, :newer}

      false ->
        {:error, :older}
    end
  end

  def append_vote(state, pid) do
    {:ok, %{state | votes: [pid | state.votes]}}
  end

  def check_majority_votes(state) do
    case length(state.votes) >= length(PG.members()) / 2 do
      true ->
        {:ok, :majority}

      false ->
        {:error, :not_enough}
    end
  end

  def check_voted(state) do
    case state.voted_for do
      nil ->
        {:ok, :not_voted}

      _ ->
        {:error, :voted}
    end
  end
end
