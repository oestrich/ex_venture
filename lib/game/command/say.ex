defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  import Game.Room.Helpers, only: [find_character: 3]

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

  @adverb_regex ~r/\[(?<adverb>.*)\]/

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

    %ParsedMessage{
      message: string,
      adverb_phrase: adverb_phrase,
      is_directed: is_directed,
      is_quoted: is_quoted
    }
  end

  defp parse_adverb_phrase(string) do
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

  def say(state = %{user: user, save: save}, parsed_message) do
    parsed_message = Message.format(parsed_message)
    state.socket |> @socket.echo(Format.say(:you, parsed_message))
    save.room_id |> @environment.say({:player, user}, Message.new(user, parsed_message))
  end

  def say_directed(state = %{user: user, save: save}, parsed_message) do
    {:ok, room} = @environment.look(save.room_id)

    case find_character(room, parsed_message.message, message: true) do
      {:error, :not_found} ->
        state.socket |> @socket.echo(gettext("No character could be found matching your text."))

      character ->
        message = Utility.strip_name(elem(character, 1), parsed_message.message)

        parsed_message =
          parsed_message
          |> Map.put(:message, message)
          |> Message.format()

        state.socket |> @socket.echo(Format.say_to(:you, character, parsed_message))

        room.id
        |> @environment.say({:player, user}, Message.say_to(user, character, parsed_message))
    end
  end

  defp maybe_hint_on_quotes(state, %{is_quoted: true}), do: Hint.gate(state, "say.quoted")
  defp maybe_hint_on_quotes(_state, _message), do: :ok
end
