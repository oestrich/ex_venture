defmodule Game.Room do
  use GenServer
  import Ecto.Query

  alias Data.Room
  alias Data.Repo

  alias Game.Session

  defmacro __using__(_opts) do
    quote do
      @room Application.get_env(:ex_mud, :game)[:room]
    end
  end

  def start_link(room) do
    GenServer.start_link(__MODULE__, room, name: pid(room.id))
  end

  def pid(id), do: :"Game.Room.room_#{id}"

  @doc """
  Load all rooms in the database
  """
  @spec all() :: [Map.t]
  def all() do
    Room |> Repo.all
  end

  @doc """
  Load the starting room.
  """
  def starting() do
    Room |> limit(1) |> Repo.one
  end

  @doc """
  Look around the room

  Fetches current room
  """
  def look(id) do
    GenServer.call(pid(id), :look)
  end

  @doc """
  Enter a room
  """
  @spec enter(id :: Integer.t, user :: {pid, Map.t}) :: :ok
  def enter(id, user) do
    GenServer.cast(pid(id), {:enter, user})
  end

  @doc """
  Leave a room
  """
  @spec leave(id :: Integer.t, user :: Map.t) :: :ok
  def leave(id, user) do
    GenServer.cast(pid(id), {:leave, user})
  end

  @doc """
  Say to the players in the room
  """
  @spec say(id :: Integer.t, sender :: pid, message :: String.t) :: :ok
  def say(id, sender,  message) do
    GenServer.cast(pid(id), {:say, sender, message})
  end

  def init(room) do
    {:ok, %{room: room, players: []}}
  end

  def handle_call(:look, _from, state = %{room: room, players: players}) do
    players = Enum.map(players, &(elem(&1, 1)))
    {:reply, Map.put(room, :players, players), state}
  end

  def handle_cast({:enter, player = {_, user}}, state = %{players: players}) do
    players |> echo_to_players("{blue}#{user.username}{/blue} enters")
    {:noreply, Map.put(state, :players, [player | players])}
  end
  def handle_cast({:leave, player = {_, user}}, state = %{players: players}) do
    players = List.delete(players, player)
    players |> echo_to_players("{blue}#{user.username}{/blue} leaves")
    {:noreply, Map.put(state, :players, players)}
  end

  def handle_cast({:say, sender, message}, state = %{players: players}) do
    players
    |> Enum.reject(&(elem(&1, 0) == sender)) # don't send to the sender
    |> echo_to_players(message)

    {:noreply, state}
  end

  defp echo_to_players(players, message) do
    Enum.each(players, fn ({session, _user}) ->
      Session.echo(session, message)
    end)
  end
end
