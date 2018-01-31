defmodule Game.Command.Crash do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  commands(["crash"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Crash"
  def help(:short), do: "Crash various processes in the game"

  def help(:full) do
    """
    #{help(:short)}

    Crash the room process you are in
    [ ] > {white}crash room{/white}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Crash.parse("crash room")
      {:room}

      iex> Game.Command.Crash.parse("crash")
      {:error, :bad_parse, "crash"}

      iex> Game.Command.Crash.parse("crash extra")
      {:error, :bad_parse, "crash extra"}

      iex> Game.Command.Crash.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("crash room"), do: {:room}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({:room}, %{user: user, save: save, socket: socket}) do
    case "admin" in user.flags do
      true ->
        save.room_id |> @room.crash()
        socket |> @socket.echo("Sent a message to crash the room.")

      false ->
        socket |> @socket.echo("You must be an admin to perform this.")
    end

    :ok
  end
end
