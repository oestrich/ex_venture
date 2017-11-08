defmodule Game.Command.Emote do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

  commands ["emote"]

  def help(:topic), do: "Emote"
  def help(:short), do: "Perform an emote"
  def help(:full) do
    """
    Performs an emote. Anything you type after emote will be added to your name.

    Example:
    [ ] > {white}emote does something{/white}
    #{Format.emote({:user, %{name: "player"}}, "does soemthing")}
    """
  end

  @doc """
  Perform an emote
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({emote}, session, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.emote({:user, user}, emote))
    room_id |> @room.emote(session, Message.emote(user, emote))
    :ok
  end
end
