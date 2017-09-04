defmodule Game.Command.Channels do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  alias Game.Channel

  @custom_parse true
  @commands ["channels", "global", "newbie"]

  @short_help "Talk to other players"
  @full_help """
  Example: global Hello, everyone!

  This chats to players in the channel
  """

  @doc """
  Parse the command into arguments

      iex> Game.Command.Channels.parse("channels")
      {}

      iex> Game.Command.Channels.parse("global hi")
      {"global", "hi"}

      iex> Game.Command.Channels.parse("newbie hi")
      {"newbie", "hi"}

      iex> Game.Command.Channels.parse("unknown hi")
      {:error, :bad_parse}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(commnd)
  def parse("channels"), do: {}
  def parse("global " <> message), do: {"global", message}
  def parse("newbie " <> message), do: {"newbie", message}
  def parse(_), do: {:error, :bad_parse}

  @doc """
  Send to all connected players
  """
  def run(command, session, state)
  def run({}, _session, %{socket: socket}) do
    channels = Channel.subscribed()
    |> Enum.map(&("  - {red}#{&1}{/red}"))
    |> Enum.join("\n")

    socket |> @socket.echo("You are subscribed to:\n#{channels}")
    :ok
  end
  def run({channel, message}, _session, %{user: user}) do
    Channel.broadcast(channel, Format.channel_say(channel, {:user, user}, message))
    :ok
  end
end
