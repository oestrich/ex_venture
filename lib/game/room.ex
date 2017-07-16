defmodule Game.Room do
  use GenServer

  alias Data.Room
  alias Data.Repo

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

  def look(id) do
    GenServer.call(pid(id), :look)
  end

  def init(room) do
    {:ok, %{room: room}}
  end

  def handle_call(:look, _from, state = %{room: room}) do
    {:reply, room, state}
  end
end
