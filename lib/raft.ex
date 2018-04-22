defmodule Raft do
  @moduledoc """
  A simple implementation of the raft protocol

  https://raft.github.io/
  """

  use GenServer

  alias Raft.PG
  alias Raft.Server

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    Process.send_after(self(), :elect, 5_000 + :rand.uniform(5_000))
    {:ok, %{leader: nil}}
  end

  # Receive a heartbeat
  def handle_cast({:heartbeat, pid}, state) do
    Logger.debug("Heartbeat from #{inspect(pid)} - #{inspect(state)}")
    heartbeat_response(pid)
    {:noreply, state}
  end

  # Respond to a heart beat
  def handle_cast({:heartbeat, :response, pid}, state) do
    Logger.debug("Heartbeat back from #{inspect(pid)} - #{inspect(state)}")
    {:noreply, state}
  end

  def handle_info(:elect, state) do
    {:ok, state} = Server.elect(state)
    {:noreply, state}
  end

  def handle_info({:leader, pid}, state) do
    {:ok, state} = Server.set_leader(state, pid)
    {:noreply, state}
  end

  # Trigger heartbeat as a leader
  def handle_info(:heartbeat, state) do
    PG.broadcast([others: true], &heartbeat/1)
    Process.send_after(self(), :heartbeat, 1_000)
    {:noreply, state}
  end
end
