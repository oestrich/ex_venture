defmodule Raft.Server do
  @moduledoc """
  Implementation for the raft server
  """

  alias Raft.PG
  alias Raft.State

  require Logger

  @behaviour Raft.Leader

  @type debug() :: map()

  @key :raft
  @cluster_size Application.get_env(:ex_venture, :cluster)[:size]
  @winner_subscriptions [Game.World.Master, Raft.Server]
  @check_election_timeout 1500

  @doc """
  Send back debug information from the raft cluster
  """
  @spec debug(State.t()) :: [debug()]
  def debug(state) do
    members = PG.members(others: true)

    debug_info =
      Enum.map(members, fn member ->
        GenServer.call(member, :state)
      end)

    [Map.put(state, :node, node()) | debug_info]
  end

  @impl true
  def leader_selected(_term) do
    :ets.insert(@key, {:is_leader?, true})
  end

  @impl true
  def node_down(), do: :ok

  @doc """
  Check for a leader already in the cluster
  """
  @spec look_for_leader(State.t()) :: {:ok, State.t()}
  def look_for_leader(state) do
    Logger.debug("Checking for a current leader.", type: :raft)

    PG.broadcast([others: true], fn pid ->
      Raft.leader_check(pid)
    end)

    {:ok, state}
  end

  @doc """
  Reply to the leader check if the node is a leader
  """
  @spec leader_check(State.t(), pid()) :: {:ok, State.t()}
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
    end, type: :raft)

    case check_term_newer(state, term) do
      {:ok, :newer} ->
        if @cluster_size == 1 do
          voted_leader(state, 1)
        else
          PG.broadcast(fn pid ->
            Raft.announce_candidate(pid, term)
          end)

          Process.send_after(
            self(),
            {:election, :check_election_status, term},
            @check_election_timeout
          )

          {:ok, %{state | highest_seen_term: term}}
        end

      {:error, :same} ->
        Logger.debug(fn ->
          "Someone already won this round, not starting"
        end, type: :raft)

        {:ok, state}

      {:error, :older} ->
        Logger.debug(fn ->
          "This term has already completed, not starting"
        end, type: :raft)

        {:ok, state}
    end
  end

  @doc """
  Vote for the leader
  """
  def vote_leader(state, pid, term) do
    Logger.debug(fn ->
      "Received ballot for term #{term}, from #{inspect(pid)}, voting"
    end, type: :raft)

    with {:ok, :newer} <- check_term_newer(state, term),
         {:ok, :not_voted} <- check_voted(state) do
      Raft.vote_for(pid, term)
      {:ok, %{state | voted_for: pid, highest_seen_term: term}}
    else
      {:error, :same} ->
        Logger.debug(fn ->
          "Received a vote for the same term"
        end, type: :raft)

        {:ok, state}

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
    end, type: :raft)

    with {:ok, :newer} <- check_term_newer(state, term),
         {:ok, state} <- append_vote(state, pid),
         {:ok, :majority} <- check_majority_votes(state) do
      PG.broadcast([others: true], fn pid ->
        Raft.new_leader(pid, term)
      end)

      voted_leader(state, term)
    else
      {:error, :same} ->
        Logger.debug("An old vote received - ignoring", type: :raft)

        {:ok, state}

      {:error, :older} ->
        Logger.debug("An old vote received - ignoring", type: :raft)

        {:ok, state}

      {:error, :not_enough} ->
        Logger.debug("Not enough votes to be a winner", type: :raft)

        append_vote(state, pid)
    end
  end

  @doc """
  Set the winner as leader
  """
  def set_leader(state, leader_pid, leader_node, term) do
    with :ok <- check_leader_different(state, leader_pid, leader_node, term),
         {:ok, :newer} <- check_term_newer(state, term) do
      Logger.debug(fn ->
        "Setting leader for term #{term} as #{inspect(leader_pid)}"
      end, type: :raft)

      :ets.insert(@key, {:is_leader?, false})

      state =
        state
        |> Map.put(:term, term)
        |> Map.put(:highest_seen_term, term)
        |> Map.put(:leader_pid, leader_pid)
        |> Map.put(:leader_node, leader_node)
        |> Map.put(:state, "follower")
        |> Map.put(:votes, [])
        |> Map.put(:voted_for, nil)

      {:ok, state}
    else
      {:error, :same} ->
        Logger.debug(fn ->
          "Another node has the same term and is a leader, starting a new term"
        end, type: :raft)

        Raft.start_election(state.term + 1)

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  defp check_leader_different(state, leader_pid, leader_node, term) do
    case state.term == term && state.leader_pid == leader_pid && state.leader_node == leader_node do
      true ->
        {:error, :leader, :same}

      false ->
        :ok
    end
  end

  @doc """
  A new node joined the cluster, assert leadership
  """
  @spec assert_leader(State.t()) :: {:ok, State.t()}
  def assert_leader(state) do
    case state.state do
      "leader" ->
        Logger.debug(fn ->
          "A new node came online, asserting leadership"
        end, type: :raft)

        PG.broadcast([others: true], fn pid ->
          Raft.new_leader(pid, state.term)
        end)

        Enum.each(@winner_subscriptions, fn module ->
          module.leader_selected(state.term)
        end)

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  @doc """
  A node went down, check if it was the leader
  """
  @spec node_down(State.t(), atom()) :: {:ok, State.t()}
  def node_down(state, node) do
    send_node_down_notice()

    case state.leader_node do
      ^node ->
        Raft.start_election(state.term + 1)

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  defp send_node_down_notice() do
    case Raft.node_is_leader?() do
      true ->
        Game.World.Master.node_down()

      false ->
        :ok
    end
  end

  @doc """
  Check if a term is newer than the local state
  """
  @spec check_term_newer(State.t(), integer()) :: boolean()
  def check_term_newer(state, term) do
    cond do
      term > state.term ->
        {:ok, :newer}

      term == state.term ->
        {:error, :same}

      true ->
        {:error, :older}
    end
  end

  def append_vote(state, pid) do
    {:ok, %{state | votes: [pid | state.votes]}}
  end

  @doc """
  Check if the node has a majority of the votes
  """
  @spec check_majority_votes(State.t()) :: {:ok, :majority} | {:error, :not_enough}
  def check_majority_votes(state) do
    case length(state.votes) >= @cluster_size / 2 do
      true ->
        {:ok, :majority}

      false ->
        {:error, :not_enough}
    end
  end

  @doc """
  Check if the node has voted in this term
  """
  @spec check_voted(State.t()) :: {:ok, :not_voted} | {:error, :voted}
  def check_voted(state) do
    case state.voted_for do
      nil ->
        {:ok, :not_voted}

      _ ->
        {:error, :voted}
    end
  end

  @doc """
  Mark the current node as the new leader for the term
  """
  @spec voted_leader(State.t(), integer()) :: {:ok, State.t()}
  def voted_leader(state, term) do
    Logger.debug(fn ->
      "Won the election for term #{term}"
    end, type: :raft)

    {:ok, state} = set_leader(state, self(), node(), term)

    Enum.each(@winner_subscriptions, fn module ->
      module.leader_selected(term)
    end)

    {:ok, %{state | state: "leader"}}
  end

  @doc """
  Check on the current term, and if it's stuck
  """
  @spec check_election_status(State.t(), integer()) :: {:ok, State.t()}
  def check_election_status(state, term) do
    Logger.debug(
      fn ->
        "Checking election status for term #{term}"
      end,
      type: :raft
    )

    case state.term < term do
      true ->
        Logger.debug("Restarting the election, it seems frozen", type: :raft)

        _check_election_status(state, term)

      false ->
        {:ok, state}
    end
  end

  defp _check_election_status(state, term) do
    case state.state do
      "candidate" ->
        Raft.start_election(term + 1)

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end
end
