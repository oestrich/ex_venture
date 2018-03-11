defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  alias Game.Utility

  import Game.Room.Helpers, only: [find_character: 3]

  commands(["say"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Say"
  def help(:short), do: "Talk to other players"

  def help(:full) do
    """
    Talk to other players in the same room. You can also talk directly to a character.

    Example:

    [ ] > {command}say Hello, everyone!{/command}
    Player says, "Hello, everyone!"

    [ ] > {command}say to guard Hello!{/command}
    Player says to Guard, "Hello!"
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Say.parse("say hello")
      {"hello"}

      iex> Game.Command.Say.parse("'hello")
      {"hello"}

      iex> Game.Command.Say.parse("say to guard hello")
      {:to, "guard hello"}

      iex> Game.Command.Say.parse("say")
      {:error, :bad_parse, "say"}

      iex> Game.Command.Say.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("say to " <> string), do: {:to, string}
  def parse("say " <> string), do: {string}
  def parse("'" <> string), do: {string}

  @impl Game.Command
  @doc """
  Says to the current room the player is in
  """
  def run(command, state)

  def run({message}, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say(:you, message))
    room_id |> @room.say({:user, user}, Message.new(user, message))
    :ok
  end

  def run({:to, who_and_message}, state = %{user: user, save: save}) do
    room = @room.look(save.room_id)

    case find_character(room, who_and_message, message: true) do
      {:error, :not_found} ->
        state.socket |> @socket.echo("No character could be found matching your text.")

      character ->
        message = Utility.strip_name(elem(character, 1), who_and_message)
        state.socket |> @socket.echo(Format.say_to(:you, character, message))

        room.id |> @room.say({:user, user}, Message.say_to(user, character, message))
    end
  end
end
