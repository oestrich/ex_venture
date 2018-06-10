defmodule Game.Environment do
  @moduledoc """
  Look at your surroundings, whether a room or an overworld
  """

  alias Game.Room
  alias Game.Overworld
  alias Game.Overworld.Sector

  @type state :: Data.Room.t()

  defmacro __using__(_opts) do
    quote do
      @environment Application.get_env(:ex_venture, :game)[:environment]
    end
  end

  @doc """
  Get the type of room based on its id
  """
  def room_type(room_id) do
    case room_id do
      "overworld:" <> _id ->
        :overworld

      _ ->
        :room
    end
  end

  @doc """
  Look around your environment
  """
  @spec look(integer() | String.t()) :: state()
  def look("overworld:" <> overworld_id) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    case :global.whereis_name({Sector, zone_id, sector}) do
      :undefined ->
        {:error, :room_offline}

      pid ->
        GenServer.call(pid, {:look, overworld_id})
    end
  end

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
  def enter("overworld:" <> overworld_id, character, reason) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:enter, overworld_id, character, reason})
  end

  def enter(id, character, reason) do
    GenServer.cast(Room.pid(id), {:enter, character, reason})
  end

  @doc """
  Leave a room

  Valid leave reasons: `:leave`, `:death`
  """
  @spec leave(integer(), Character.t(), atom()) :: :ok
  def leave("overworld:" <> overworld_id, character, reason) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:leave, overworld_id, character, reason})
  end

  def leave(id, character, reason) do
    GenServer.cast(Room.pid(id), {:leave, character, reason})
  end

  @doc """
  Notify characters in a room of an event
  """
  @spec notify(integer(), Character.t(), tuple()) :: :ok
  def notify("overworld:" <> overworld_id, character, event) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:notify, overworld_id, character, event})
  end

  def notify(id, character, event) do
    GenServer.cast(Room.pid(id), {:notify, character, event})
  end

  @doc """
  Say to the players in the room
  """
  @spec say(integer(), pid(), Message.t()) :: :ok
  def say("overworld:" <> overworld_id, sender, message) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:say, overworld_id, sender, message})
  end

  def say(id, sender, message) do
    GenServer.cast(Room.pid(id), {:say, sender, message})
  end

  @doc """
  Emote to the players in the room
  """
  @spec emote(integer(), pid(), Message.t()) :: :ok
  def emote("overworld:" <> overworld_id, sender, message) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:emote, overworld_id, sender, message})
  end

  def emote(id, sender, message) do
    GenServer.cast(Room.pid(id), {:emote, sender, message})
  end

  @doc """
  Pick up the item
  """
  @spec pick_up(integer(), Item.t()) :: :ok
  def pick_up("overworld:" <> overworld_id, item) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.call(Sector.pid(zone_id, sector), {:pick_up, overworld_id, item})
  end

  def pick_up(id, item) do
    GenServer.call(Room.pid(id), {:pick_up, item})
  end

  @doc """
  Pick up currency
  """
  @spec pick_up_currency(integer()) :: :ok
  def pick_up_currency("overworld:" <> overworld_id) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.call(Sector.pid(zone_id, sector), {:pick_up_currency, overworld_id})
  end

  def pick_up_currency(id) do
    GenServer.call(Room.pid(id), :pick_up_currency)
  end

  @doc """
  Drop an item into a room
  """
  @spec drop(integer(), Character.t(), Item.t()) :: :ok
  def drop("overworld:" <> overworld_id, who, item) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:drop, overworld_id, who, item})
  end

  def drop(id, who, item) do
    GenServer.cast(Room.pid(id), {:drop, who, item})
  end

  @doc """
  Drop currency into a room
  """
  @spec drop_currency(integer(), Character.t(), integer()) :: :ok
  def drop_currency("overworld:" <> overworld_id, who, currency) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:drop_currency, overworld_id, who, currency})
  end

  def drop_currency(id, who, currency) do
    GenServer.cast(Room.pid(id), {:drop_currency, who, currency})
  end

  @doc """
  Update the character after a stats change
  """
  @spec update_character(integer(), tuple()) :: :ok
  def update_character("overworld:" <> overworld_id, character) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), {:update_character, overworld_id, character})
  end

  def update_character(id, character) do
    GenServer.cast(Room.pid(id), {:update_character, character})
  end

  @doc """
  Link the current process against the room's pid, finds by id
  """
  def link("overworld:" <> overworld_id) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    case :global.whereis_name({Sector, zone_id, sector}) do
      :undefined ->
        {:error, :room_offline}

      pid ->
        Process.link(pid)
    end
  end

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
  def unlink("overworld:" <> overworld_id) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    case :global.whereis_name({Sector, zone_id, sector}) do
      :undefined ->
        {:error, :room_offline}

      pid ->
        Process.unlink(pid)
    end
  end

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
  def crash("overworld:" <> overworld_id) do
    {zone_id, sector} = Overworld.sector_from_overworld_id(overworld_id)
    GenServer.cast(Sector.pid(zone_id, sector), :crash)
  end

  def crash(id) do
    GenServer.cast(Room.pid(id), :crash)
  end
end
