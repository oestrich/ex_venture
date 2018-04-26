defmodule Raft.PG do
  @moduledoc """
  Raft process group helper
  """

  @key :raft

  @doc """
  Join the process group for raft communication
  """
  @spec join() :: :ok
  def join() do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())
  end

  @doc """
  Broadcast a message to the members
  """
  @spec broadcast((pid() -> any())) :: :ok
  def broadcast(fun) do
    members() |> Enum.each(fun)
  end

  @doc """
  Broadcast a message to the members
  """
  @spec broadcast(Keyword.t(), (pid() -> any())) :: :ok
  def broadcast([others: true], fun) do
    [others: true] |> members() |> Enum.each(fun)
  end

  @doc """
  Get the group members
  """
  @spec members() :: [pid()]
  def members() do
    :pg2.get_members(:raft)
  end

  @doc """
  Get the other group members
  """
  @spec members(Keyword.t()) :: [pid()]
  def members([others: true]) do
    members() |> Enum.reject(&(&1 == self()))
  end
end
