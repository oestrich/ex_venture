defmodule Game.Environment do
  @moduledoc """
  Look at your surroundings, whether a room or an overworld
  """

  alias Game.Room

  @type state :: Data.Room.t()

  defmacro __using__(_opts) do
    quote do
      @environment Application.get_env(:ex_venture, :game)[:environment]
    end
  end

  @doc """
  Look around your environment
  """
  @spec look(integer() | String.t()) :: state()
  def look(id) do
    case :global.whereis_name({Room, id}) do
      :undefined ->
        {:error, :room_offline}

      pid ->
        GenServer.call(pid, :look)
    end
  end

  @doc """
  Enter a room

  Valid enter reasons: `:enter`, `:respawn`
  """
  @spec enter(integer(), Character.t(), atom()) :: :ok
  def enter(id, character, reason) do
    GenServer.cast(Room.pid(id), {:enter, character, reason})
  end

  @doc """
  Leave a room

  Valid leave reasons: `:leave`, `:death`
  """
  @spec leave(integer(), Character.t(), atom()) :: :ok
  def leave(id, character, reason) do
    GenServer.cast(Room.pid(id), {:leave, character, reason})
  end

  @doc """
  Notify characters in a room of an event
  """
  @spec notify(integer(), Character.t(), tuple()) :: :ok
  def notify(id, character, event) do
    GenServer.cast(Room.pid(id), {:notify, character, event})
  end

  @doc """
  Say to the players in the room
  """
  @spec say(integer(), pid(), Message.t()) :: :ok
  def say(id, sender, message) do
    GenServer.cast(Room.pid(id), {:say, sender, message})
  end

  @doc """
  Emote to the players in the room
  """
  @spec emote(integer(), pid(), Message.t()) :: :ok
  def emote(id, sender, message) do
    GenServer.cast(Room.pid(id), {:emote, sender, message})
  end

  @doc """
  Pick up the item
  """
  @spec pick_up(integer(), Item.t()) :: :ok
  def pick_up(id, item) do
    GenServer.call(Room.pid(id), {:pick_up, item})
  end

  @doc """
  Pick up currency
  """
  @spec pick_up_currency(integer()) :: :ok
  def pick_up_currency(id) do
    GenServer.call(Room.pid(id), :pick_up_currency)
  end

  @doc """
  Drop an item into a room
  """
  @spec drop(integer(), Character.t(), Item.t()) :: :ok
  def drop(id, who, item) do
    GenServer.cast(Room.pid(id), {:drop, who, item})
  end

  @doc """
  Drop currency into a room
  """
  @spec drop_currency(integer(), Character.t(), integer()) :: :ok
  def drop_currency(id, who, currency) do
    GenServer.cast(Room.pid(id), {:drop_currency, who, currency})
  end

  @doc """
  Update the character after a stats change
  """
  @spec update_character(integer(), tuple()) :: :ok
  def update_character(id, character) do
    GenServer.cast(Room.pid(id), {:update_character, character})
  end

  @doc """
  Link the current process against the room's pid, finds by id
  """
  def link(id) do
    case :global.whereis_name({Room, id}) do
      :undefined ->
        :ok

      pid ->
        Process.link(pid)
    end
  end

  @doc """
  Unlink the current process against the room's pid, finds by id
  """
  def unlink(id) do
    case :global.whereis_name({Room, id}) do
      :undefined ->
        :ok

      pid ->
        Process.unlink(pid)
    end
  end

  @doc """
  Crash a room process with an unmatched cast

  There should always remain no matching clause for this cast
  """
  def crash(id) do
    GenServer.cast(Room.pid(id), :crash)
  end
end
