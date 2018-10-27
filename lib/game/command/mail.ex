defmodule Game.Command.Mail do
  @moduledoc """
  The "mail" command
  """

  use Game.Command
  use Game.Command.Editor

  alias Game.Account
  alias Game.Format.Mail, as: FormatMail
  alias Game.Hint
  alias Game.Mail

  commands(["mail"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Mail"
  def help(:short), do: "Send mail to other players"

  def help(:full) do
    """
    #{help(:short)}.

    View mail
    [ ] > mail

    Read a piece of mail
    [ ] > mail read 10

    Sending mail is a multi-step process. Start by instructing to send a
    new piece of mail.

    [ ] > mail new player

    Then the title will be prompted for. After that you start typing the
    body of the mail. To finish the body send an empty line.
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Mail.parse("mail")
      {:unread}

      iex> Game.Command.Mail.parse("mail read 1")
      {:read, "1"}

      iex> Game.Command.Mail.parse("mail new player")
      {:new, "player"}

      iex> Game.Command.Mail.parse("mail send player")
      {:new, "player"}

      iex> Game.Command.Mail.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("mail"), do: {:unread}
  def parse("mail read " <> id), do: {:read, id}
  def parse("mail new " <> player), do: {:new, player}
  def parse("mail send " <> player), do: {:new, player}

  @impl Game.Command
  @doc """
  Send mail to players
  """
  def run(command, state)

  def run({:unread}, state = %{socket: socket, user: user}) do
    case Mail.unread_mail_for(user) do
      [] ->
        socket |> @socket.echo(gettext("You have no unread mail."))

      mail ->
        {:paginate, FormatMail.list_mail(mail), state}
    end
  end

  def run({:read, id}, state = %{socket: socket, user: user}) do
    case Mail.get(user, id) do
      nil ->
        socket |> @socket.echo(gettext("The mail requested could not be found. Please try again."))

      mail ->
        Mail.mark_read!(mail)
        {:paginate, FormatMail.display_mail(mail), state}
    end
  end

  def run({:new, player}, state = %{socket: socket}) do
    case Account.get_player(player) do
      {:ok, player} ->
        commands =
          state.commands
          |> Map.put(:mail, %{player: player, title: nil, body: []})

        state = %{state | commands: commands}

        socket |> @socket.prompt("Title: ")

        {:editor, __MODULE__, state}

      {:error, :not_found} ->
        socket |> @socket.echo(gettext("Could not find \"%{player}\".", player: player))
    end
  end

  @impl Game.Command.Editor
  def editor({:text, title}, state = %{commands: %{mail: %{title: nil}}}) do
    %{commands: %{mail: mail}} = state
    mail = Map.put(mail, :title, title)
    state = %{state | commands: %{state.commands | mail: mail}}

    state |> Hint.gate("mail.body")
    state.socket |> @socket.echo(gettext("Mail:"))

    {:update, state}
  end

  def editor({:text, line}, state) do
    %{commands: %{mail: mail}} = state
    lines = Map.get(mail, :body) ++ [line]
    mail = Map.put(mail, :body, lines)
    state = %{state | commands: %{state.commands | mail: mail}}

    {:update, state}
  end

  def editor(:complete, state) do
    %{commands: %{mail: mail}} = state

    Mail.create(state.user, mail)

    commands =
      state
      |> Map.get(:commands)
      |> Map.delete(:mail)

    {:update, Map.put(state, :commands, commands)}
  end
end
