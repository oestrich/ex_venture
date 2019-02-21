defmodule Game.Format.Channels do
  @moduledoc """
  Format functions for channels, including local room communication
  """

  import Game.Format.Context

  alias Game.Format

  @doc """
  Format a channel message

  Example:

      iex> Channels.channel_say(%{name: "global", color: "red"}, %{type: "npc", name: "NPC"}, %{message: "Hello"})
      ~s(\\\\[{red}global{/red}\\\\] {npc}NPC{/npc} says, {say}"Hello"{/say})
  """
  @spec channel_say(String.t(), Character.t(), map()) :: String.t()
  def channel_say(channel, sender, parsed_message) do
    context()
    |> assign(:channel_name, channel_name(channel))
    |> assign(:say, say(sender, parsed_message))
    |> Format.template("\\[[channel_name]\\] [say]")
  end

  @doc """
  Color the channel's name
  """
  @spec channel_name(Channel.t()) :: String.t()
  def channel_name(channel) do
    "{#{channel.color}}#{channel.name}{/#{channel.color}}"
  end

  @doc """
  Format a say message

  Example:

      iex> Channels.say(:you, %{message: "Hello"})
      ~s[You say, {say}"Hello"{/say}]

      iex> Channels.say(%{type: "npc", name: "NPC"}, %{message: "Hello"})
      ~s[{npc}NPC{/npc} says, {say}"Hello"{/say}]

      iex> Channels.say(%{type: "player", name: "Player"}, %{message: "Hello"})
      ~s[{player}Player{/player} says, {say}"Hello"{/say}]

      iex> Channels.say(%{type: "player", name: "Player"}, %{adverb_phrase: "softly", message: "Hello"})
      ~s[{player}Player{/player} says softly, {say}"Hello"{/say}]
  """
  @spec say(Character.t(), map()) :: String.t()
  def say(:you, message) do
    context()
    |> assign(:message, message.message)
    |> assign(:adverb_phrase, Map.get(message, :adverb_phrase, nil))
    |> Format.template(~s(You say[ adverb_phrase], {say}"[message]"{/say}))
  end

  def say(character, message) do
    context()
    |> assign(:name, Format.name(character))
    |> assign(:message, message.message)
    |> assign(:adverb_phrase, Map.get(message, :adverb_phrase, nil))
    |> Format.template(~s([name] says[ adverb_phrase], {say}"[message]"{/say}))
  end

  @doc """
  Format a say to message

  Example:

      iex> Channels.say_to(:you, %{type: "player", name: "Player"}, %{message: "Hello"})
      ~s[You say to {player}Player{/player}, {say}"Hello"{/say}]

      iex> Channels.say_to(:you, %{type: "player", name: "Player"}, %{message: "Hello", adverb_phrase: "softly"})
      ~s[You say softly to {player}Player{/player}, {say}"Hello"{/say}]

      iex> Channels.say_to(%{type: "npc", name: "NPC"}, %{type: "player", name: "Player"}, %{message: "Hello"})
      ~s[{npc}NPC{/npc} says to {player}Player{/player}, {say}"Hello"{/say}]

      iex> Channels.say_to(%{type: "player", name: "Player"}, %{type: "npc", name: "Guard"}, %{message: "Hello"})
      ~s[{player}Player{/player} says to {npc}Guard{/npc}, {say}"Hello"{/say}]

      iex> Channels.say_to(%{type: "player", name: "Player"}, %{type: "npc", name: "Guard"}, %{message: "Hello", adverb_phrase: "softly"})
      ~s[{player}Player{/player} says softly to {npc}Guard{/npc}, {say}"Hello"{/say}]
  """
  @spec say_to(Character.t(), Character.t(), map()) :: String.t()
  def say_to(:you, sayee, parsed_message) do
    context()
    |> assign(:sayee, Format.name(sayee))
    |> assign(:message, parsed_message.message)
    |> assign(:adverb_phrase, Map.get(parsed_message, :adverb_phrase, nil))
    |> Format.template(~s(You say[ adverb_phrase] to [sayee], {say}"[message]"{/say}))
  end

  def say_to(sayer, sayee, parsed_message) do
    context()
    |> assign(:sayer, Format.name(sayer))
    |> assign(:sayee, Format.name(sayee))
    |> assign(:message, parsed_message.message)
    |> assign(:adverb_phrase, Map.get(parsed_message, :adverb_phrase, nil))
    |> Format.template(~s([sayer] says[ adverb_phrase] to [sayee], {say}"[message]"{/say}))
  end

  @doc """
  Format an emote message

  Example:

      iex> Channels.emote(%{type: "npc", name: "NPC"}, "does something")
      ~s[{npc}NPC{/npc} {say}does something{/say}]

      iex> Channels.emote(%{type: "player", name: "Player"}, "does something")
      ~s[{player}Player{/player} {say}does something{/say}]
  """
  @spec emote(Character.t(), String.t()) :: String.t()
  def emote(character, emote) do
    ~s[#{Format.name(character)} {say}#{emote}{/say}]
  end

  @doc """
  Format a whisper message

      iex> Channels.whisper(%{type: "player", name: "Player"}, "secret message")
      ~s[{player}Player{/player} whispers to you, {say}"secret message"{/say}]
  """
  @spec whisper(Character.t(), String.t()) :: String.t()
  def whisper(sender, message) do
    context()
    |> assign(:sender, Format.name(sender))
    |> assign(:message, message)
    |> Format.template("[sender] whispers to you, {say}\"[message]\"{/say}")
  end

  @doc """
  Format a whisper message from the player

      iex> Channels.send_whisper(%{type: "player", name: "Player"}, "secret message")
      ~s[You whisper to {player}Player{/player}, {say}"secret message"{/say}]
  """
  @spec send_whisper(Character.t(), String.t()) :: String.t()
  def send_whisper(receiver, message) do
    context()
    |> assign(:receiver, Format.name(receiver))
    |> assign(:message, message)
    |> Format.template("You whisper to [receiver], {say}\"[message]\"{/say}")
  end

  @doc """
  Format a whisper overheard message for others in the room

      iex> Channels.whisper_overheard(%{type: "player", name: "Player"}, %{type: "npc", name: "Guard"})
      ~s[You overhear {player}Player{/player} whispering to {npc}Guard{/npc}.]
  """
  @spec whisper_overheard(Character.t(), String.t()) :: String.t()
  def whisper_overheard(sender, receiver) do
    context()
    |> assign(:sender, Format.name(sender))
    |> assign(:receiver, Format.name(receiver))
    |> Format.template("You overhear [sender] whispering to [receiver].")
  end

  @doc """
  Format a tell message

      iex> Channels.tell(%{type: "player", name: "Player"}, "secret message")
      ~s[{player}Player{/player} tells you, {say}"secret message"{/say}]
  """
  @spec tell(Character.t(), String.t()) :: String.t()
  def tell(sender, message) do
    context()
    |> assign(:sender, Format.name(sender))
    |> assign(:message, message)
    |> Format.template("[sender] tells you, {say}\"[message]\"{/say}")
  end

  @doc """
  Format a tell message, for display of the sender

      iex> Channels.send_tell(%{type: "player", name: "Player"}, "secret message")
      ~s[You tell {player}Player{/player}, {say}"secret message"{/say}]
  """
  @spec send_tell(Character.t(), String.t()) :: String.t()
  def send_tell(character, message) do
    context()
    |> assign(:receiver, Format.name(character))
    |> assign(:message, message)
    |> Format.template("You tell [receiver], {say}\"[message]\"{/say}")
  end
end
