defmodule Game.Message do
  @moduledoc """
  Player or NPC message, something said
  """

  defstruct [:type, :sender, :message, :formatted, from_gossip: false]

  alias Data.User
  alias Game.Format.Channels, as: FormatChannels

  @type t :: %{
          type: :player | :npc,
          sender: User.t(),
          message: String.t(),
          formatted: String.t()
        }

  def new(player, message), do: say(player, message)

  def say(player, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :player,
      sender: player,
      message: parsed_message.message,
      formatted: FormatChannels.say({:player, player}, parsed_message)
    }
  end

  def say_to(player, character, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :player,
      sender: player,
      message: parsed_message.message,
      formatted: FormatChannels.say_to({:player, player}, character, parsed_message)
    }
  end

  def emote(player, message) do
    %__MODULE__{
      type: :player,
      sender: player,
      message: message,
      formatted: FormatChannels.emote({:player, player}, message)
    }
  end

  @doc """
  Pre-formatted
  """
  def social(player, emote) do
    %__MODULE__{
      type: :player,
      sender: player,
      message: emote,
      formatted: emote
    }
  end

  def broadcast(player, channel, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :player,
      sender: player,
      message: parsed_message.message,
      formatted: FormatChannels.channel_say(channel, {:player, player}, parsed_message)
    }
  end

  def tell(player, message) do
    %__MODULE__{
      type: :player,
      sender: player,
      message: message,
      formatted: FormatChannels.tell({:player, player}, message)
    }
  end

  def whisper(player, message) do
    message = format(message)

    %__MODULE__{
      type: :player,
      sender: player,
      message: message,
      formatted: FormatChannels.whisper({:player, player}, message)
    }
  end

  def gossip_broadcast(channel, message) do
    name = "#{message.name}@#{message.game}"
    player = %{name: name}

    %__MODULE__{
      type: :player,
      sender: player,
      message: message.message,
      formatted: FormatChannels.channel_say(channel, {:player, player}, message),
      from_gossip: true
    }
  end

  def npc(npc, message), do: npc_say(npc, message)

  def npc_say(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: FormatChannels.say({:npc, npc}, %{message: message})
    }
  end

  def npc_emote(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: FormatChannels.emote({:npc, npc}, message)
    }
  end

  def npc_tell(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: FormatChannels.tell({:npc, npc}, message)
    }
  end

  @doc """
  Capitalize and punctuate a message before sending it out
  """
  @spec format(ParsedMessage.t()) :: ParsedMessage.t()
  def format(parsed_message) when is_map(parsed_message) do
    %{parsed_message | message: format(parsed_message.message)}
  end

  @spec format(String.t()) :: String.t()
  def format(message) do
    message
    |> capitalize_first_letter()
    |> maybe_punctuate()
  end

  defp capitalize_first_letter(string) do
    case String.graphemes(string) do
      [] ->
        ""

      [letter | rest] ->
        letter = String.upcase(letter)
        Enum.join([letter | rest])
    end
  end

  defp maybe_punctuate(message) do
    case Regex.match?(~r/[^\w]$/, message) do
      true ->
        message

      false ->
        "#{message}."
    end
  end
end
