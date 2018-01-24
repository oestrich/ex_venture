defmodule Game.Session.Login do
  @moduledoc """
  Login workflow

  Displays the MOTD and asks for a login, then password. Will push off to
  creating an account if that is asked for.
  """

  use Networking.Socket
  use Game.Room

  require Logger

  alias Game.Authentication
  alias Game.Config
  alias Game.Channel
  alias Game.Session
  alias Game.Session.GMCP
  alias Metrics.PlayerInstrumenter

  @doc """
  Start text for logging in
  """
  @spec start(socket :: pid) :: :ok
  def start(socket) do
    socket |> @socket.echo("#{ExVenture.version()}\n#{motd()}")

    socket
    |> @socket.prompt(
      "What is your player name (Enter {white}create{/white} for a new account)? "
    )
  end

  defp motd() do
    Config.motd("Welcome to ExVenture.")
  end

  @doc """
  Sign a user in

  Edit the state to be signed in and active
  """
  @spec login(map, pid, map) :: map
  def login(user, socket, state) do
    Session.Registry.register(user)

    PlayerInstrumenter.login(user)

    state =
      state
      |> Map.put(:user, user)
      |> Map.put(:save, user.save)
      |> Map.put(:state, "after_sign_in")

    socket |> @socket.echo("Welcome, #{user.name}!")
    socket |> @socket.set_user_id(user.id)

    socket |> @socket.echo(Config.after_sign_in_message())
    socket |> @socket.echo("[Press enter to continue]")

    state
  end

  def after_sign_in(state = %{user: user}, session) do
    @room.enter(user.save.room_id, {:user, user})
    session |> Session.recv("look")
    state |> GMCP.character()

    Enum.each(user.save.channels, &Channel.join/1)
    Channel.join_tell({:user, user})

    state
    |> Map.put(:state, "active")
  end

  def sign_in(user_id, state = %{socket: socket}) do
    case Authentication.find_user(user_id) do
      nil ->
        socket |> @socket.disconnect()
        state

      user ->
        user |> process_login(state)
    end
  end

  def process("create", state = %{socket: socket}) do
    socket |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end

  def process(password, state = %{socket: socket, login: %{name: name}}) do
    socket |> @socket.tcp_option(:echo, true)

    case Authentication.find_and_validate(name, password) do
      {:error, :invalid} ->
        PlayerInstrumenter.login_fail()
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        state

      user ->
        user |> process_login(state)
    end
  end

  def process(message, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    socket |> @socket.tcp_option(:echo, false)
    Map.merge(state, %{login: %{name: message}})
  end

  defp process_login(user, state = %{socket: socket}) do
    case already_signed_in?(user) do
      true ->
        socket |> @socket.echo("Sorry, this player is already logged in.")
        socket |> @socket.disconnect()
        state

      false ->
        user |> login(socket, state |> Map.delete(:login))
    end
  end

  defp already_signed_in?(user) do
    Session.Registry.connected_players()
    |> Enum.any?(&(elem(&1, 1).id == user.id))
  end
end
