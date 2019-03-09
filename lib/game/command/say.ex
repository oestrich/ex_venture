defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  import Game.Room.Helpers, only: [find_character: 3]

  alias Game.Character
  alias Game.Events.RoomHeard
  alias Game.Format.Channels, as: FormatChannels
  alias Game.Hint
  alias Game.Utility

  defmodule ParsedMessage do
    @moduledoc """
    A parsed string of the user's message
    """

    @doc """
    - `message`: the full string of the user
    - `is_directed`: if the user is directing this at someone, if the message starts with a `>`
    """
    defstruct [:message, :is_directed, :is_quoted, :adverb_phrase]
  end

  commands([{"say", ["'"]}], parse: false)

  @adverb_regex ~r/^\[(?<adverb>.*)\]/

  @impl Game.Command
  def help(:topic), do: "Say"
  def help(:short), do: "Talk to other players"

  def help(:full) do
    """
    Talk to other players in the same room. You can also talk directly to a character.

    Example:

    [ ] > {command}say Hello, everyone!{/command}
    Player says, "Hello, everyone!"

    Say directly to a character in the room:
    [ ] > {command}say >guard Hello!{/command}
    Player says to Guard, "Hello!"

    Add an adverb phrase
    [ ] > {command}say [meakly] Hello{/command}
    Player says meakly, "Hello"
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Say.parse("say hello")
      {"hello"}

      iex> Game.Command.Say.parse("'hello")
      {"hello"}

      iex> Game.Command.Say.parse("say >guard hello")
      {">guard hello"}

      iex> Game.Command.Say.parse("say")
      {:error, :bad_parse, "say"}

      iex> Game.Command.Say.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("say " <> string), do: {string}
  def parse("'" <> string), do: {string}

  @doc """
  Parse a message that a user wants to say. Pulls out if the user wants to
  direct at someone, and the adverb phrase.
  """
  def parse_message(string) do
    {string, adverb_phrase} = parse_adverb_phrase(string)
    is_directed = String.starts_with?(string, ">")
    is_quoted = String.starts_with?(string, "\"")

    string =
      string
      |> String.replace(~r/^>/, "")
      |> String.replace(~r/^"/, "")
      |> String.replace(~r/"$/, "")
      |> VML.escape()

    %ParsedMessage{
      message: string,
      adverb_phrase: adverb_phrase,
      is_directed: is_directed,
      is_quoted: is_quoted
    }
  end

  defp parse_adverb_phrase(string) do
    string = String.trim(string)

    case Regex.run(@adverb_regex, string) do
      nil ->
        {string, nil}

      [match, adverb_phrase] ->
        string =
          string
          |> String.replace(match, "")
          |> String.trim()

        {string, adverb_phrase}
    end
  end

  @impl Game.Command
  @doc """
  Says to the current room the player is in
  """
  def run(command, state)

  def run({message}, state) do
    parsed_message = parse_message(message)

    state |> maybe_hint_on_quotes(parsed_message)

    case parsed_message.is_directed do
      true ->
        state |> say_directed(parsed_message)

      false ->
        state |> say(parsed_message)
    end

    :ok
  end

  def say(state = %{character: character, save: save}, parsed_message) do
    parsed_message = Message.format(parsed_message)
    state |> Socket.echo(FormatChannels.say(:you, parsed_message))

    message = Message.new(character, parsed_message)
    event = %RoomHeard{character: Character.to_simple(character), message: message}
    Environment.notify(save.room_id, event.character, event)
  end

  def say_directed(state = %{character: character, save: save}, parsed_message) do
    {:ok, room} = Environment.look(save.room_id)

    case find_character(room, parsed_message.message, message: true) do
      {:error, :not_found} ->
        state |> Socket.echo(gettext("No character could be found matching your text."))

      {:ok, directed_character} ->
        message = Utility.strip_name(directed_character, parsed_message.message)

        parsed_message =
          parsed_message
          |> Map.put(:message, message)
          |> Message.format()

        message = FormatChannels.say_to(:you, directed_character, parsed_message)
        state |> Socket.echo(message)

        message = Message.say_to(character, directed_character, parsed_message)
        event = %RoomHeard{character: Character.to_simple(character), message: message}
        Environment.notify(room.id, event.character, event)
    end
  end

  defp maybe_hint_on_quotes(state, %{is_quoted: true}), do: Hint.gate(state, "say.quoted")

  defp maybe_hint_on_quotes(_state, _message), do: :ok
end
