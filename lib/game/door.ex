defmodule Game.Door do
  @moduledoc """
  Door tracker, know if the door is open or closed
  """

  use GenServer

  alias Data.Exit

  @ets_table :doors
  @closed "closed"
  @open "open"

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #
  # Client
  #

  @doc """
  Maybe load a door, only if the exit has a door
  """
  @spec maybe_load(room_exit :: Exit.t) :: :ok
  def maybe_load(room_exit)
  def maybe_load(%{id: id, has_door: true}), do: load(id)
  def maybe_load(_), do: :ok

  @doc """
  Load a new door into the ETS table
  """
  @spec load(exit_id :: integer) :: :ok
  def load(%{id: id}), do: load(id)
  def load(exit_id) do
    GenServer.call(__MODULE__, {:load, exit_id})
  end

  @doc """
  Get the state of a door
  """
  @spec get(exit_id :: integer) :: String.t
  def get(exit_id) do
    case :ets.lookup(@ets_table, exit_id) do
      [{_, state}] -> state
      _ -> nil
    end
  end

  @doc """
  Set the state of a door, state must be `#{@open}` or `#{@closed}`
  """
  @spec set(exit_id :: integer, state :: String.t) :: :ok
  def set(%{id: id}, state) when state in [@open, @closed], do: set(id, state)
  def set(exit_id, state) when state in [@open, @closed] do
    GenServer.call(__MODULE__, {:set, exit_id, state})
  end

  @doc """
  Check if a door is closed
  """
  @spec closed?(exit_id :: integer) :: boolean
  def closed?(exit_id) do
    case get(exit_id) do
      nil -> nil
      state -> state == @closed
    end
  end

  @doc """
  Check if a door is open
  """
  @spec open?(exit_id :: integer) :: boolean
  def open?(exit_id) do
    case get(exit_id) do
      nil -> nil
      state -> state == @open
    end
  end

  def remove(%{id: id}) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    create_table()
    {:ok, %{}}
  end

  def handle_call({:load, exit_id}, _from, state) do
    :ets.insert(@ets_table, {exit_id, @closed})
    {:reply, @closed, state}
  end

  def handle_call({:set, exit_id, door_state}, _from, state) do
    :ets.insert(@ets_table, {exit_id, door_state})
    {:reply, door_state, state}
  end

  def handle_call({:remove, exit_id}, _from, state) do
    :ets.delete(@ets_table, exit_id)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(@ets_table)
    create_table()

    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_table, [:set, :protected, :named_table])
  end
end
