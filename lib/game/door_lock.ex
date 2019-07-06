defmodule Game.DoorLock do
  @moduledoc """
  Door tracker, know if the door is open or closed
  """

  use GenServer

  alias Data.Exit

  @typedoc """
  Door lock status is `locked` or `unlocked`
  """
  @type status :: String.t()

  @key :door_locks
  @locked "locked"
  @unlocked "unlocked"

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #
  # Client
  #

  @doc """
  Maybe load a door lock, only if the exit has a door lock
  """
  @spec maybe_load(Exit.t()) :: :ok
  def maybe_load(room_exit)
  def maybe_load(%{door_id: door_id, has_door: true, has_lock: true}), do: load(door_id)
  def maybe_load(_), do: :ok

  @doc """
  Load a new door into the ETS table
  """
  @spec load(String.t()) :: :ok

  def load(%{door_id: id}), do: load(id)

  def load(door_id) do
    members = :pg2.get_members(@key)

    Enum.each(members, fn member ->
      GenServer.call(member, {:load, door_id})
    end)

    @locked
  end

  @doc """
  Get the state of a door
  """
  @spec get(String.t()) :: String.t()
  def get(%{door_id: door_id}), do: get(door_id)
  
  def get(door_id) do
    case Cachex.get(@key, door_id) do
      {:ok, state} when state != nil ->
        state

      _ ->
        load(door_id)
    end
  end

  @doc """
  Set the state of a door lock, state must be `#{@locked}` or `#{@unlocked}`
  """
  @spec set(Exit.t(), status()) :: :ok
  def set(%{door_id: door_id}, state) when state in [@locked, @unlocked], do: set(door_id, state)

  @spec set(String.t(), status()) :: :ok
  def set(door_id, state) when state in [@locked, @unlocked] do
    members = :pg2.get_members(@key)

    Enum.each(members, fn member ->
      GenServer.call(member, {:set, door_id, state})
    end)

    state
  end

  @doc """
  Check if a door is locked
  """
  @spec locked?(String.t()) :: boolean
  def locked?(door_id) do
    case get(door_id) do
      nil ->
        nil

      state ->
        state == @locked
    end
  end

  @doc """
  Check if a door is unlocked
  """
  @spec unlocked?(String.t()) :: boolean
  def unlocked?(door_id) do
    case get(door_id) do
      nil ->
        nil

      state ->
        state == @unlocked
    end
  end

  @doc """
  Remove an exit from the ETS table after being deleted.
  """
  @spec remove(Exit.t()) :: :ok
  def remove(room_exit)

  def remove(%{door_id: door_id}) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:remove, door_id})
    end)
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
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    {:ok, %{}}
  end

  def handle_call({:load, door_id}, _from, state) do
    Cachex.put(@key, door_id, @locked)
    {:reply, @locked, state}
  end

  def handle_call({:set, door_id, door_state}, _from, state) do
    Cachex.put(@key, door_id, door_state)
    {:reply, door_state, state}
  end

  def handle_call({:remove, door_id}, _from, state) do
    Cachex.del(@key, door_id)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)
    {:reply, :ok, state}
  end
end
