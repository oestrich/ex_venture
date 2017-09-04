defmodule Game.Command.Global do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  alias Game.Channel

  @commands ["global"]

  @short_help "Talk to other players"
  @full_help """
  Example: say Hello, everyone!

  This chats to every player connected
  """

  @doc """
  Send to all connected players
  """
  def run(command, session, state)
  def run({message}, _session, %{user: user}) do
    message = ~s({red}[global]{/red} {blue}#{user.name}{/blue} says, {green}"#{message}"{/green})

    Channel.broadcast("global", message)

    :ok
  end
end
