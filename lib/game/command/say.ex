defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  commands(["say"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Say"
  def help(:short), do: "Talk to other players"

  def help(:full) do
    """
    Talk to other players in the same room.

    Example:
    [ ] > {white}say Hello, everyone!{/white}
    #{Format.say({:user, %{name: "Player"}}, "Hello, everyone!")}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Say.parse("say hello")
      {"hello"}

      iex> Game.Command.Say.parse("'hello")
      {"hello"}

      iex> Game.Command.Say.parse("say")
      {:error, :bad_parse, "say"}

      iex> Game.Command.Say.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("say " <> string), do: {string}
  def parse("'" <> string), do: {string}

  @impl Game.Command
  @doc """
  Says to the current room the player is in
  """
  def run(command, state)

  def run({message}, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say({:user, user}, message))
    room_id |> @room.say({:user, user}, Message.new(user, message))
    :ok
  end
end
