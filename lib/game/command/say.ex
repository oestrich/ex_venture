defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  commands ["say"]

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

  @doc """
  Says to the current room the player is in
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({message}, session, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say({:user, user}, message))
    room_id |> @room.say(session, Message.new(user, message))
    :ok
  end
end
