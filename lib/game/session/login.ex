defmodule Game.Session.Login do
  @moduledoc """
  Login workflow

  Displays the MOTD and asks for a login, then password. Will push off to
  creating an account if that is asked for.
  """

  require Logger

  alias Data.Repo
  alias Data.Room
  alias Game.Authentication
  alias Game.Channel
  alias Game.Character
  alias Game.Command.Config, as: CommandConfig
  alias Game.Environment
  alias Game.Mail
  alias Game.MOTD
  alias Game.Player
  alias Game.Session
  alias Game.Session.Process
  alias Game.Session.GMCP
  alias Game.Session.Regen
  alias Game.Socket
  alias Metrics.PlayerInstrumenter
  alias Web.Router.Helpers, as: Routes

  @doc """
  Start text for logging in
  """
  def start(state) do
    state |> Socket.echo("#{ExVenture.version()}\n#{MOTD.random_motd()}")
    prompt = "What is your player name? (Enter {command}create{/command} for a new account) "
    state |> Socket.prompt(prompt)
  end

  @doc """
  Sign a player in

  Edit the state to be signed in and active
  """
  def login(player, character, state) do
    self() |> Process.schedule_save()
    self() |> Process.schedule_inactive_check()
    self() |> Process.schedule_heartbeat()

    PlayerInstrumenter.login(player)

    state =
      state
      |> setup_state_after_login(player, character)
      |> Map.put(:state, "after_sign_in")

    state |> Socket.set_character_id(character.id)
    state |> CommandConfig.push_config(character.save.config)
    state |> GMCP.config_actions()

    message = """
    Welcome, #{state.character.name}!

    #{MOTD.random_asim()}
    """

    state |> Socket.echo(message)

    case Mail.unread_mail_for(player) do
      [] ->
        :ok

      _ ->
        state |> Socket.echo("You have mail.")
    end

    message = "{command send='Sign In'}\\[Press enter to continue\\]{/command}"
    state |> Socket.echo(message)

    state
  end

  def after_sign_in(state, session) do
    with :ok <- check_room(state) do
      finish_login(state, session)
    else
      {:error, :room, :missing} ->
        state |> Socket.echo("The room you were in has been deleted.")
        state |> Socket.echo("Sending you back to the starting room!")

        starting_save = Game.Config.starting_save()

        save = Map.put(state.save, :room_id, starting_save.room_id)
        state = Player.update_save(state, save)
        finish_login(state, session)
    end
  end

  defp finish_login(state = %{character: character}, session) do
    Session.Registry.register(character)
    Session.Registry.player_online(character)

    Environment.link(character.save.room_id)
    Environment.enter(character.save.room_id, character, :login)

    session |> Session.recv("look")
    state |> GMCP.character()
    state |> GMCP.character_skills()
    state |> GMCP.discord_status()

    Enum.each(character.save.channels, &Channel.join/1)
    Channel.join_tell(Character.to_simple(character))

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

  def sign_in(character_id, state) do
    case Authentication.find_character(character_id) do
      nil ->
        state |> Socket.disconnect()
        state

      character ->
        character |> process_login(state)
    end
  end

  def process("create", state) do
    state |> Session.CreateAccount.start()
    state |> Map.put(:state, "create")
  end

  # catch all after the process has started
  def process(_, state = %{login: %{name: _name}}) do
    state
  end

  def process(message, state) do
    link = Routes.public_connection_url(Web.Endpoint, :authorize, id: state.id)
    echo = "Please sign in via the website to authorize this connection."
    echo = "#{echo}\n\n{link}#{link}{/link}"
    state |> Socket.echo(echo)
    Map.merge(state, %{login: %{name: message}})
  end

  defp process_login(character, state) do
    with :ok <- check_already_signed_in(character),
         :ok <- check_disabled(character.user) do
      character.user |> login(character, state |> Map.delete(:login))
    else
      {:error, :signed_in} ->
        message = "Sorry, this player is already logged in."
        state |> Socket.echo(message)

        state |> Socket.disconnect()
        state

      {:error, :disabled} ->
        message = "Sorry, your account has been disabled. Please contact the admins."
        state |> Socket.echo(message)
        state |> Socket.disconnect()
        state
    end
  end

  @doc """
  Recover a session after crashing
  """
  @spec recover_session(integer(), State.t()) :: State.t()
  def recover_session(character_id, state) do
    case Authentication.find_character(character_id) do
      nil ->
        state |> Socket.disconnect()
        state

      character ->
        character |> process_recovery(state)
    end
  end

  defp process_recovery(character, state) do
    with :ok <- check_already_signed_in(character) do
      character |> _recover_session(state)
    else
      {:error, :signed_in} ->
        state |> Socket.echo("Sorry, this player is already logged in.")
        state |> Socket.disconnect()
        state
    end
  end

  defp _recover_session(character, state) do
    Session.Registry.register(character)

    state = setup_state_after_login(state, character.user, character)
    state = after_sign_in(state, self())

    state |> Socket.echo("Session recovering...")
    state |> Process.prompt()
    state |> Regen.maybe_trigger_regen()

    state
  end

  defp setup_state_after_login(state, user, character) do
    state
    |> Map.put(:user, user)
    |> Map.put(:character, character)
    |> Map.put(:save, character.save)
  end

  defp check_already_signed_in(character) do
    case Session.Registry.player_online?(character) do
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
