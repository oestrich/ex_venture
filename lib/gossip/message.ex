defmodule Gossip.Message do
  @moduledoc """
  Message on a channel struct
  """

  @type t :: %__MODULE__{}
  @type send :: %{
    name: String.t(),
    message: String.t(),
  }

  @doc """
  The payload of a "messages/broadcast" event

  ```{
    "channel": "gossip",
    "message": "Hello everyone!",
    "game": "ExVenture",
    "name": "Player"
  }```
  """
  defstruct [:channel, :game, :name, :message]
end
