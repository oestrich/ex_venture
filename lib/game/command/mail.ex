defmodule Game.Command.Mail do
  @moduledoc """
  The "mail" command
  """

  use Game.Command

  alias Game.Format
  alias Game.Mail

  commands ["mail"], parse: false

  @impl Game.Command
  def help(:topic), do: "Mail"
  def help(:short), do: "Send mail to other players"
  def help(:full) do
    """
    #{help(:short)}

    View mail
    [ ] > mail
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Mail.parse("mail")
      {:unread}

      iex> Game.Command.Mail.parse("mail read 1")
      {:read, "1"}

      iex> Game.Command.Mail.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t) :: {any()}
  def parse(command)
  def parse("mail"), do: {:unread}
  def parse("mail read " <> id), do: {:read, id}
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  Send to all connected players
  """
  @impl Game.Command
  def run(command, session, state)
  def run({:unread}, _session, state = %{socket: socket, user: user}) do
    case Mail.unread_mail_for(user) do
      [] ->
        socket |> @socket.echo("You have no unread mail.")
        :ok
      mail ->
        socket |> @socket.echo("You have #{length(mail)} piece of mail.")
        {:paginate, Format.list_mail(mail), state}
    end
  end

  def run({:read, id}, _session, state = %{socket: socket, user: user}) do
    case Mail.get(user, id) do
      nil ->
        socket |> @socket.echo("The mail requested could not be found. Please try again.")
        :ok
      mail ->
        Mail.mark_read!(mail)
        {:paginate, Format.display_mail(mail), state}
    end
  end
end
