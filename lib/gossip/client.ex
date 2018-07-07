defmodule Gossip.Client do
  @moduledoc """
  Behaviour for integrating Gossip into your game
  """

  @type user_agent :: String.t()
  @type channel_name :: String.t()
  @type player_name :: String.t()
  @type message :: Gossip.Message.t()

  @doc """
  Get the game's User Agent.

  This should return the game name with a version number.
  """
  @callback user_agent() :: user_agent()

  @doc """
  Get the channels you want to subscribe to on start
  """
  @callback channels() :: [channel_name()]

  @doc """
  Get the current names of connected players
  """
  @callback players() :: [player_name()]

  @doc """
  A new message was received from Gossip on a channel
  """
  @callback message_broadcast(message()) :: :ok
end
