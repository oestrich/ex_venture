defmodule Game.Session.Login do
  @moduledoc """
  Login workflow

  Displays the MOTD and asks for a login, then password. Will push off to
  creating an account if that is asked for.
  """

  use Networking.Socket
  use Game.Environment

  import Game.Gettext, only: [dgettext: 2]

  require Logger

  alias Data.Repo
  alias Data.Room
  alias Game.Authentication
  alias Game.Command.Config, as: CommandConfig
  alias Game.Channel
  alias Game.Mail
  alias Game.MOTD
  alias Game.Player
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
    socket |> @socket.echo("#{ExVenture.version()}\n#{MOTD.random_motd()}")

    prompt = dgettext("login", "What is your player name? (Enter {command}create{/command} for a new account) ")
    socket |> @socket.prompt(prompt)
  end

  @doc """
  Sign a player in

  Edit the state to be signed in and active
  """
  def login(player, character, socket, state) do
    self() |> Process.schedule_save()
    self() |> Process.schedule_inactive_check()
    self() |> Process.schedule_heartbeat()

    PlayerInstrumenter.login(player)

    state =
      state
      |> setup_state_after_login(player, character)
      |> Map.put(:state, "after_sign_in")

    socket |> @socket.set_user_id(player.id)
    state |> CommandConfig.push_config(player.save.config)
    state |> GMCP.config_actions()

    message = """
    Welcome, #{state.character.name}!

    #{MOTD.random_asim()}
    """

    socket |> @socket.echo(message)

    case Mail.unread_mail_for(player) do
      [] ->
        :ok

      _ ->
        socket |> @socket.echo(dgettext("login", "You have mail."))
    end

    socket |> @socket.echo(dgettext("login", "{command send='Sign In'}[Press enter to continue]{/command}"))

    state
  end

  def after_sign_in(state, session) do
    with :ok <- check_room(state) do
      finish_login(state, session)
    else
      {:error, :room, :missing} ->
        state.socket |> @socket.echo(dgettext("login", "The room you were in has been deleted."))
        state.socket |> @socket.echo(dgettext("login", "Sending you back to the starting room!"))

        starting_save = Game.Config.starting_save()

        save = Map.put(state.save, :room_id, starting_save.room_id)
        state = Player.update_save(state, save)
        finish_login(state, session)
    end
  end

  defp finish_login(state = %{user: player, character: character}, session) do
    Session.Registry.register(player)
    Session.Registry.player_online(player)

    @environment.link(character.save.room_id)
    @environment.enter(character.save.room_id, {:player, character}, :login)
    session |> Session.recv("look")
    state |> GMCP.character()
    state |> GMCP.character_skills()
    state |> GMCP.discord_status()

    Enum.each(character.save.channels, &Channel.join/1)
    Channel.join_tell({:player, character})

    state
    |> Regen.maybe_trigger_regen()
    |> Map.put(:state, "active")
  end

  defp check_room(state) do
    case state.save.room_id do
      "overworld:" <> _overworld_id ->
        :ok

      room_id ->
        case Repo.get(Room, room_id) do
          nil ->
            {:error, :room, :missing}

          _room ->
            :ok
        end
    end
  end

  def sign_in(user_id, state = %{socket: socket}) do
    case Authentication.find_user(user_id) do
      nil ->
        socket |> @socket.disconnect()
        state

      player ->
        player |> process_login(state)
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
    link = Routes.public_connection_url(Web.Endpoint, :authorize, id: state.id)
    echo = dgettext("login", "Please sign in via the website to authorize this connection.")
    echo = "#{echo}\n\n{link}#{link}{/link}"
    state.socket |> @socket.echo(echo)
    Map.merge(state, %{login: %{name: message}})
  end

  defp process_login(player, state) do
    with :ok <- check_already_signed_in(player),
         :ok <- check_disabled(player) do
      character = get_character_from_user(player)
      player |> login(character, state.socket, state |> Map.delete(:login))
    else
      {:error, :signed_in} ->
        state.socket |> @socket.echo(dgettext("login", "Sorry, this player is already logged in."))
        state.socket |> @socket.disconnect()
        state

      {:error, :disabled} ->
        message = dgettext("login", "Sorry, your account has been disabled. Please contact the admins.")
        state.socket |> @socket.echo(message)
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

      player ->
        player |> process_recovery(state)
    end
  end

  defp process_recovery(player, state = %{socket: socket}) do
    with :ok <- check_already_signed_in(player) do
      player |> _recover_session(state)
    else
      {:error, :signed_in} ->
        socket |> @socket.echo(dgettext("login", "Sorry, this player is already logged in."))
        socket |> @socket.disconnect()
        state
    end
  end

  defp _recover_session(user, state) do
    Session.Registry.register(user)

    character = get_character_from_user(user)

    state = setup_state_after_login(state, user, character)
    state = after_sign_in(state, self())

    state.socket |> @socket.echo(dgettext("login", "Session recovering..."))
    state |> Process.prompt()
    state |> Regen.maybe_trigger_regen()

    state
  end

  defp get_character_from_user(user) do
    user = Repo.preload(user, [characters: [:race, :class]])
    List.first(user.characters)
  end

  defp setup_state_after_login(state, user, character) do
    state
    |> Map.put(:user, user)
    |> Map.put(:character, character)
    |> Map.put(:save, character.save)
  end

  defp check_already_signed_in(player) do
    case Session.Registry.player_online?(player) do
      true ->
        {:error, :signed_in}

      false ->
        :ok
    end
  end

  defp check_disabled(player) do
    case "disabled" in player.flags do
      true ->
        {:error, :disabled}

      false ->
        :ok
    end
  end
end
