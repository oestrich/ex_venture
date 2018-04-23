defmodule Raft do
  @moduledoc """
  A simple implementation of the raft protocol

  https://raft.github.io/
  """

  use GenServer

  alias Raft.PG
  alias Raft.Server
  alias Raft.State

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Announce a node as running for leader
  """
  def announce_candidate(pid, term) do
    GenServer.cast(pid, {:election, :running, self(), term})
  end

  @doc """
  Vote for a node as the leader
  """
  def vote_for(pid, term) do
    GenServer.cast(pid, {:election, :cast_vote, self(), term})
  end

  @doc """
  Set the node as the new leader for a term
  """
  def new_leader(pid, term) do
    GenServer.cast(pid, {:election, :winner, self(), term})
  end

  @doc """
  Send a heartbeat from the leader to the connected nodes
  """
  def heartbeat(pid) do
    GenServer.cast(pid, {:heartbeat, self()})
  end

  @doc """
  Heartbeat response from the connected nodes
  """
  def heartbeat_response(pid) do
    GenServer.cast(pid, {:heartbeat, :response, self()})
  end

  def init(_) do
    PG.join()
    Process.send_after(self(), {:election, :start, 1}, 5_000 + :rand.uniform(5_000))

    state = %State{
      state: :candidate,
      term: 0,
      highest_seen_term: 0,
      leader_pid: nil,
      votes: []
    }

    {:ok, state}
  end

  # Receive a heartbeat
  def handle_cast({:heartbeat, pid}, state) do
    Logger.debug(fn ->
      "Heartbeat from #{inspect(pid)} - #{inspect(state)}"
    end)
    heartbeat_response(pid)
    {:noreply, state}
  end

  # Respond to a heart beat
  def handle_cast({:heartbeat, :response, pid}, state) do
    Logger.debug(fn ->
      "Heartbeat back from #{inspect(pid)} - #{inspect(state)}"
    end)
    {:noreply, state}
  end

  def handle_cast({:election, :running, pid, term}, state) do
    {:ok, state} = Server.vote_leader(state, pid, term)
    {:noreply, state}
  end

  def handle_cast({:election, :cast_vote, pid, term}, state) do
    {:ok, state} = Server.vote_received(state, pid, term)
    {:noreply, state}
  end

  def handle_cast({:election, :winner, pid, term}, state) do
    {:ok, state} = Server.set_leader(state, pid, term)
    {:noreply, state}
  end

  def handle_info({:election, :start, term}, state) do
    {:ok, state} = Server.start_election(state, term)
    {:noreply, state}
  end

  # Trigger heartbeat as a leader
  def handle_info(:heartbeat, state) do
    PG.broadcast([others: true], &heartbeat/1)
    Process.send_after(self(), :heartbeat, 1_000)
    {:noreply, state}
  end
end
