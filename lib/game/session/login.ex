defmodule Game.Session.Login do
  use Networking.Socket

  alias Game.Authentication
  alias Game.Session

  @doc """
  Start text for logging in
  """
  @spec start(socket :: pid) :: nil
  def start(socket) do
    socket |> @socket.echo("Welcome to ExMud.\n\nEnter {white}create{/white} to create a new account.\n")
    socket |> @socket.prompt("What is your player name? ")
  end

  @doc """
  Sign a user in

  Edit the state to be signed in and active
  """
  @spec login(user :: Map.t, socket :: pid, state :: Map.t) :: Map.t
  def login(user, socket, state) do
    Session.Registry.register(user)

    socket |> @socket.echo("Welcome, #{user.username}")

    state
    |> Map.put(:user, user)
    |> Map.put(:state, "active")
  end

  def process("create", state = %{socket: socket}) do
    socket |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end
  def process(password, state = %{socket: socket, login: %{username: username}}) do
    case Authentication.find_and_validate(username, password) do
      {:error, :invalid} ->
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        state
      user ->
        user |> login(socket, state |> Map.delete(:login))
    end
  end
  def process(message, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    Map.merge(state, %{login: %{username: message}})
  end
end
