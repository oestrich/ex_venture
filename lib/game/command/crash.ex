defmodule Game.Command.Crash do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  @required_flags ["admin"]

  @zone Application.get_env(:ex_venture, :game)[:zone]

  commands(["crash"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Crash"
  def help(:short), do: "Crash various processes in the game"

  def help(:full) do
    """
    #{help(:short)}

    Crash the room process you are in
    [ ] > {command}crash room{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Crash.parse("crash room")
      {:room}

      iex> Game.Command.Crash.parse("crash zone")
      {:zone}

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
  def parse("crash zone"), do: {:zone}

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

  def run({:zone}, %{user: user, save: save, socket: socket}) do
    case "admin" in user.flags do
      true ->
        {:ok, room} = save.room_id |> @room.look()
        room.zone_id |> @zone.crash()
        socket |> @socket.echo("Sent a message to crash the zone.")

      false ->
        socket |> @socket.echo("You must be an admin to perform this.")
    end

    :ok
  end
end
