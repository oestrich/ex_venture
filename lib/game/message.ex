defmodule Game.Message do
  @moduledoc """
  Player or NPC message, something said
  """

  defstruct [:type, :sender, :message, :formatted]

  alias Data.User
  alias Game.Format

  @type t :: %{
    type: :user | :npc,
    sender: User.t,
    message: String.t,
    formatted: String.t,
  }

  def new(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.say({:user, user}, message),
    }
  end

  def emote(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.emote({:user, user}, message),
    }
  end

  def npc_say(npc, message), do: npc(npc, message)
  def npc(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.say({:npc, npc}, message),
    }
  end

  def npc_emote(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.emote({:npc, npc}, message),
    }
  end
end
