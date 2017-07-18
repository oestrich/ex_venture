defmodule Game.Session.Login do
  use Networking.Socket
  use Game.Room

  alias Data.Config
  alias Game.Authentication
  alias Game.Command
  alias Game.Session

  @doc """
  Start text for logging in
  """
  @spec start(socket :: pid) :: nil
  def start(socket) do
    socket |> @socket.echo("#{motd()}\n\nEnter {white}create{/white} to create a new account.\n")
    socket |> @socket.prompt("What is your player name? ")
  end

  defp motd() do
    case Config.motd() do
      nil -> "Welcome to ExMud."
      motd -> motd
    end
  end

  @doc """
  Sign a user in

  Edit the state to be signed in and active
  """
  @spec login(user :: Map.t, session :: pid, socket :: pid, state :: Map.t) :: Map.t
  def login(user, session, socket, state) do
    Session.Registry.register(user)

    socket |> @socket.echo("\nWelcome, #{user.username}!\n")

    @room.enter(user.save.room_id, {session, user})

    state
    |> Map.put(:user, user)
    |> Map.put(:save, user.save)
    |> Map.put(:state, "active")
  end

  def process("create", _session, state = %{socket: socket}) do
    socket |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end
  def process(password, session, state = %{socket: socket, login: %{username: username}}) do
    socket |> @socket.tcp_option(:echo, true)
    case Authentication.find_and_validate(username, password) do
      {:error, :invalid} ->
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        state
      user ->
        state = user |> login(session, socket, state |> Map.delete(:login))
        Command.run({:look}, session, state)
        state
    end
  end
  def process(message, _session, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    socket |> @socket.tcp_option(:echo, false)
    Map.merge(state, %{login: %{username: message}})
  end
end
