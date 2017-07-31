defmodule Game.Session.Login do
  @moduledoc """
  Login workflow

  Displays the MOTD and asks for a login, then password. Will push off to
  creating an account if that is asked for.
  """

  use Networking.Socket
  use Game.Room

  alias Data.Config
  alias Game.Authentication
  alias Game.Format
  alias Game.Session

  @doc """
  Start text for logging in
  """
  @spec start(socket :: pid) :: :ok
  def start(socket) do
    socket |> @socket.echo("#{version()}\n#{motd()}\nEnter {white}create{/white} to create a new account.")
    socket |> @socket.prompt("What is your player name? ")
  end

  defp motd() do
    case Config.motd() do
      nil -> "Welcome to ExVenture."
      motd -> motd
    end
  end

  def version() do
    ex_venture = :application.loaded_applications()
    |> Enum.find(&(elem(&1, 0) == :ex_venture))
    "ExVenture v#{elem(ex_venture, 2)}"
  end

  @doc """
  Sign a user in

  Edit the state to be signed in and active
  """
  @spec login(user :: map, session :: pid, socket :: pid, state :: map) :: map
  def login(user, session, socket, state) do
    Session.Registry.register(user)

    socket |> @socket.echo("Welcome, #{user.name}!")

    @room.enter(user.save.room_id, {:user, session, user})
    session |> Session.recv("look")

    state
    |> Map.put(:user, user)
    |> Map.put(:save, user.save)
    |> Map.put(:state, "active")
  end

  def process("create", _session, state = %{socket: socket}) do
    socket |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end
  def process(password, session, state = %{socket: socket, login: %{name: name}}) do
    socket |> @socket.tcp_option(:echo, true)
    case Authentication.find_and_validate(name, password) do
      {:error, :invalid} ->
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        state
      user ->
        state = user |> login(session, socket, state |> Map.delete(:login))
        socket |> @socket.prompt(Format.prompt(user, user.save))
        state
    end
  end
  def process(message, _session, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    socket |> @socket.tcp_option(:echo, false)
    Map.merge(state, %{login: %{name: message}})
  end
end
