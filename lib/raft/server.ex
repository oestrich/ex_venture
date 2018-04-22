defmodule Raft.Server do
  @moduledoc """
  Implementation for the raft server
  """

  alias Raft.PG

  require Logger

  @doc """
  Try to elect yourself as the leader
  """
  def elect(state) do
    with {:error, :no_leader} <- check_leader(state) do
      PG.broadcast(fn pid ->
        send(pid, {:leader, self()})
      end)

      Process.send_after(self(), :heartbeat, 1_000)
    end

    {:ok, state}
  end

  def set_leader(state, pid) do
    with {:error, :no_leader} <- check_leader(state) do
      Logger.info("Selecing a new leader #{inspect(self())}")
      {:ok, %{state | leader: pid}}
    else
      _ ->
        {:ok, state}
    end
  end

  defp check_leader(state) do
    pid = self()

    case state.leader do
      ^pid ->
        {:ok, :leader}

      nil ->
        {:error, :no_leader}

      _ ->
        {:error, :node_only}
    end
  end
end
