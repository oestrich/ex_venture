defmodule Game.Command.Channels do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  alias Game.Channel
  alias Game.Command.Say
  alias Game.Message

  commands(["channels"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Channels"
  def help(:short), do: "Talk to other players"

  def help(:full) do
    """
    #{help(:short)}

    List out all of the channels you are subscribed to
    [ ] > {command}channels{/command}

    Use the name of the channel before your message to broadcast to that channel.
    [ ] > {command}global Hello!{/command}

    Turn a channel on:
    [ ] > {command}channels on global{/command}

    Turn a channel off:
    [ ] > {command}channels off global{/command}
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
      nil ->
        {:error, :bad_parse, channel_message}

      _ ->
        {channel, Enum.join(message, " ")}
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

    message = gettext("You are subscribed to:")
    socket |> @socket.echo("#{message}\n#{channels}")
  end

  def run({:join, channel}, state = %{user: user}) do
    with {:ok, channel} <- get_channel(channel),
         false <- in_channel?(channel.name, user) do
      Channel.join(channel.name)
    else
      _ ->
        state.socket |> @socket.echo(gettext("You are already part of this channel."))
    end
  end

  def run({:leave, channel}, state) do
    case get_joined_channel(channel, state) do
      {:ok, channel} ->
        Channel.leave(channel.name)
        state.socket |> @socket.echo(gettext("You have left %{channel_name}.", channel_name: Format.channel_name(channel)))

      {:error, :not_found} ->
        state.socket |> @socket.echo(gettext("You are not part of that channel."))
    end
  end

  def run({channel_name, ""}, state) do
    with {:ok, channel} <- get_channel(channel_name) do
      case in_channel?(channel.name, state.user) do
        true ->
          state.socket |> @socket.echo(gettext("You are part of %{channel_name}.", channel_name: Format.channel_name(channel)))

        false ->
          state.socket |> @socket.echo(gettext("You are not part of %{channel_name}.", Format.channel_name(channel)))
      end
    else
      _ ->
        :ok
    end
  end

  def run({channel, message}, state) do
    with {:ok, channel} <- get_joined_channel(channel, state) do
      parsed_message = Say.parse_message(message)
      Channel.broadcast(channel.name, Message.broadcast(state.user, channel, parsed_message))
      :ok
    else
      {:error, :not_found} ->
        state.socket |> @socket.echo(gettext("You are not part of this channel."))
    end
  end

  defp get_joined_channel(channel, state) do
    case in_channel?(channel, state.user) do
      true ->
        get_channel(channel)

      false ->
        {:error, :not_found}
    end
  end

  defp get_channel(channel) do
    case Game.Channels.get(channel) do
      nil ->
        {:error, :not_found}

      channel ->
        {:ok, channel}
    end
  end

  defp in_channel?(channel, %{save: %{channels: channels}}) do
    channel in channels
  end
end
