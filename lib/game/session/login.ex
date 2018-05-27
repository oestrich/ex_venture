defmodule Game.Session.Login do
  @moduledoc """
  Login workflow

  Displays the MOTD and asks for a login, then password. Will push off to
  creating an account if that is asked for.
  """

  use Networking.Socket
  use Game.Room

  require Logger

  alias Data.Repo
  alias Data.Room
  alias Game.Authentication
  alias Game.Command.Config, as: CommandConfig
  alias Game.Config
  alias Game.Channel
  alias Game.Mail
  alias Game.Session
  alias Game.Session.Process
  alias Game.Session.GMCP
  alias Game.Session.Regen
  alias Metrics.PlayerInstrumenter
  alias Web.Router.Helpers, as: Routes

  @doc """
  Start text for logging in
  """
  @spec start(socket :: pid) :: :ok
  def start(socket) do
    socket |> @socket.echo("#{ExVenture.version()}\n#{motd()}")

    socket
    |> @socket.prompt(
      "What is your player name (Enter {command}create{/command} for a new account)? "
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
    Session.Registry.player_online(user)

    self() |> Process.schedule_save()
    self() |> Process.schedule_inactive_check()

    PlayerInstrumenter.login(user)

    state =
      state
      |> Map.put(:user, user)
      |> Map.put(:save, user.save)
      |> Map.put(:state, "after_sign_in")

    socket |> @socket.set_user_id(user.id)
    state |> CommandConfig.push_config(user.save.config)

    message = """
    Welcome, #{user.name}!

    #{Config.after_sign_in_message()}
    """

    socket |> @socket.echo(message)

    case Mail.unread_mail_for(user) do
      [] -> :ok
      _ -> socket |> @socket.echo("You have mail.")
    end

    socket |> @socket.echo("[Press enter to continue]")

    state
  end

  def after_sign_in(state, session) do
    with {:ok, _room} <- check_room(state) do
      finish_login(state, session)
    else
      {:error, :room, :missing} ->
        state.socket |> @socket.echo("The room you were in has been deleted.")
        state.socket |> @socket.echo("Sending you back to the starting room!")

        starting_save = Game.Config.starting_save()

        %{user: user, save: save} = state

        save = Map.put(save, :room_id, starting_save.room_id)
        user = %{user | save: save}
        state = %{state | user: user, save: save}
        finish_login(state, session)
    end
  end

  defp finish_login(state = %{user: user}, session) do
    @room.link(user.save.room_id)
    @room.enter(user.save.room_id, {:user, user}, :login)
    session |> Session.recv("look")
    state |> GMCP.character()

    Enum.each(user.save.channels, &Channel.join/1)
    Channel.join_tell({:user, user})

    state
    |> Regen.maybe_trigger_regen()
    |> Map.put(:state, "active")
  end

  defp check_room(state) do
    case Repo.get(Room, state.save.room_id) do
      nil ->
        {:error, :room, :missing}

      room ->
        {:ok, room}
    end
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

  def process("create", state) do
    state.socket |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end

  # catch all after the process has started
  def process(_, state = %{login: %{name: _name}}) do
    state
  end

  def process(message, state) do
    echo = """
    Please sign in via the website to authorize this connection.

    #{Routes.public_connection_url(Web.Endpoint, :authorize, id: state.id)}
    """

    state.socket |> @socket.echo(echo)

    Map.merge(state, %{login: %{name: message}})
  end

  defp process_login(user, state) do
    with :ok <- check_already_signed_in(user),
         :ok <- check_disabled(user) do
      user |> login(state.socket, state |> Map.delete(:login))
    else
      {:error, :signed_in} ->
        state.socket |> @socket.echo("Sorry, this player is already logged in.")
        state.socket |> @socket.disconnect()
        state

      {:error, :disabled} ->
        state.socket |> @socket.echo("Sorry, your account has been disabled. Please contact the admins.")
        state.socket |> @socket.disconnect()
        state
    end
  end

  @doc """
  Recover a session after crashing
  """
  @spec recover_session(integer(), State.t()) :: State.t()
  def recover_session(user_id, state) do
    case Authentication.find_user(user_id) do
      nil ->
        state.socket |> @socket.disconnect()
        state

      user ->
        user |> process_recovery(state)
    end
  end

  defp process_recovery(user, state = %{socket: socket}) do
    with :ok <- check_already_signed_in(user) do
      user |> _recover_session(state)
    else
      {:error, :signed_in} ->
        socket |> @socket.echo("Sorry, this player is already logged in.")
        socket |> @socket.disconnect()
        state
    end
  end

  defp _recover_session(user, state) do
    Session.Registry.register(user)

    state =
      state
      |> Map.put(:user, user)
      |> Map.put(:save, user.save)

    state = after_sign_in(state, self())

    state.socket |> @socket.echo("Session recovered... Welcome back.")
    state |> Process.prompt()
    state |> Regen.maybe_trigger_regen()

    state
  end

  defp check_already_signed_in(user) do
    online? =
      Session.Registry.connected_players()
      |> Enum.any?(&(&1.user.id == user.id))

    case online? do
      true ->
        {:error, :signed_in}

      false ->
        :ok
    end
  end

  defp check_disabled(user) do
    case "disabled" in user.flags do
      true ->
        {:error, :disabled}

      false ->
        :ok
    end
  end
end
