defmodule Game.Message do
  @moduledoc """
  Player or NPC message, something said
  """

  defstruct [:type, :sender, :message, :formatted]

  alias Data.User
  alias Game.Format

  @type t :: %{
          type: :user | :npc,
          sender: User.t(),
          message: String.t(),
          formatted: String.t()
        }

  def new(user, message), do: say(user, message)

  def say(user, parsed_message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.say({:user, user}, parsed_message)
    }
  end

  def say_to(user, character, parsed_message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.say_to({:user, user}, character, parsed_message)
    }
  end

  def emote(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.emote({:user, user}, message)
    }
  end

  def broadcast(user, channel, parsed_message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.channel_say(channel, {:user, user}, parsed_message)
    }
  end

  def tell(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.tell({:user, user}, message)
    }
  end

  def whisper(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.whisper({:user, user}, message)
    }
  end

  def npc(npc, message), do: npc_say(npc, message)

  def npc_say(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.say({:npc, npc}, %{message: message})
    }
  end

  def npc_emote(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.emote({:npc, npc}, message)
    }
  end

  def npc_tell(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.tell({:npc, npc}, message)
    }
  end
end
