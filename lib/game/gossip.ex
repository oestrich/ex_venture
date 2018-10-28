defmodule Game.Gossip do
  @moduledoc """
  Callback module for Gossip
  """

  require Logger

  alias Game.Channel
  alias Game.Channels
  alias Game.Character
  alias Game.Message
  alias Game.Session

  @behaviour Gossip.Client.Core
  @behaviour Gossip.Client.Players
  @behaviour Gossip.Client.Tells
  @behaviour Gossip.Client.Games

  @impl true
  def user_agent() do
    ExVenture.version()
  end

  @impl true
  def channels() do
    Enum.map(Channels.gossip_channels(), &(&1.gossip_channel))
  end

  @impl true
  def players() do
    Session.Registry.connected_players()
    |> Enum.map(&(&1.player.name))
  end

  @impl true
  def message_broadcast(message) do
    with {:ok, channel} <- Channels.gossip_channel(message.channel),
         true <- Squabble.node_is_leader?() do
      message = Message.gossip_broadcast(channel, message)
      Channel.broadcast(channel.name, message)

      :ok
    else
      _ ->
        :ok
    end
  end

  @impl true
  def player_sign_in(game_name, player_name) do
    Logger.info(fn ->
      "Gossip - new player sign in #{player_name}@#{game_name}"
    end)

    case Squabble.node_is_leader?() do
      true ->
        Session.Registry.connected_players()
        |> Enum.each(fn %{player: player} ->
          Character.notify({:player, player}, {"gossip/player-online", game_name, player_name})
        end)

      false ->
        :ok
    end
  end

  @impl true
  def player_sign_out(game_name, player_name) do
    Logger.info(fn ->
      "Gossip - new player sign out #{player_name}@#{game_name}"
    end)

    case Squabble.node_is_leader?() do
      true ->
        Session.Registry.connected_players()
        |> Enum.each(fn %{player: player} ->
          Character.notify({:player, player}, {"gossip/player-offline", game_name, player_name})
        end)

      false ->
        :ok
    end
  end

  @impl true
  def player_update(game_name, player_names) do
    Logger.debug(fn ->
      "Received update for game #{game_name} - #{inspect(player_names)}"
    end)
  end

  @impl true
  def tell_receive(from_game, from_player, to_player, message) do
    Logger.info(fn ->
      "Received a new tell from #{from_player}@#{from_game} to #{to_player}"
    end)

    with true <- Squabble.node_is_leader?,
         {:ok, player} <- Session.Registry.find_player(to_player) do
      player_name = "#{from_player}@#{from_game}"
      Channel.tell({:player, player}, {:gossip, player_name}, Message.tell(%{name: player_name}, message))

      :ok
    else
      _ ->
        :ok
    end
  end

  @impl true
  def game_update(_game), do: :ok

  @impl true
  def game_connect(_game), do: :ok

  @impl true
  def game_disconnect(_game), do: :ok
end
