defmodule Game.Command.Channels do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  alias Game.Channel
  alias Game.Message

  commands(["channels"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Channels"
  def help(:short), do: "Talk to other players"

  def help(:full) do
    """
    #{help(:short)}

    Talk to players in a channel
    [ ] > {command}global Hello!{/command}

    Turn a channel on:
    [ ] > {command}channel on global{/command}

    Turn a channel off:
    [ ] > {command}channel off global{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Channels.parse("channels")
      {}

      iex> Game.Command.Channels.parse("channels off global")
      {:leave, "global"}

      iex> Game.Command.Channels.parse("channels on global")
      {:join, "global"}

      iex> Game.Command.Channels.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("channels"), do: {}
  def parse("channels off " <> channel), do: {:leave, channel}
  def parse("channels on " <> channel), do: {:join, channel}

  def parse(channel_message) when is_binary(channel_message) do
    [channel | message] = String.split(channel_message)

    case Game.Channels.get(channel) do
      nil -> {:error, :bad_parse, channel_message}
      _ -> {channel, Enum.join(message, " ")}
    end
  end

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({}, %{socket: socket}) do
    channels =
      Channel.subscribed()
      |> Enum.map(&"  - {#{&1.color}}#{&1.name}{/#{&1.color}}")
      |> Enum.join("\n")

    socket |> @socket.echo("You are subscribed to:\n#{channels}")
    :ok
  end

  def run({:join, channel}, %{user: user}) do
    join_channel(channel, user)
    :ok
  end

  def run({:leave, channel}, %{user: user}) do
    case in_channel?(channel, user) do
      true ->
        Channel.leave(channel)

      false ->
        nil
    end

    :ok
  end

  def run({channel, message}, %{user: user}) do
    case in_channel?(channel, user) do
      true ->
        case Game.Channels.get(channel) do
          nil ->
            nil

          channel ->
            Channel.broadcast(channel.name, Message.broadcast(user, channel, message))
        end

      false ->
        nil
    end

    :ok
  end

  defp in_channel?(channel, %{save: %{channels: channels}}) do
    channel in channels
  end

  defp join_channel(channel, user) do
    case Game.Channels.get(channel) do
      nil ->
        nil

      _ ->
        case in_channel?(channel, user) do
          false ->
            Channel.join(channel)

          true ->
            nil
        end
    end
  end
end
