defmodule Game.Command do
  @moduledoc """
  Parses and runs commands from players
  """

  @typedoc """
  A tuple with the first element being the command to run

  Example:

      {Game.Command.Run, "Hi there"}
  """
  @type t :: {module :: atom(), args :: []}

  @doc """
  Run a command

  Returns `:ok` or `{:update, new_state}` and the Session server will accept the new state.
  """
  @callback run(args :: list, session :: pid, state :: map) :: :ok | {:update, state :: map}

  defmacro __using__(_opts) do
    quote do
      use Networking.Socket
      use Game.Room

      alias Game.Format
      alias Game.Message
      alias Game.Session

      @behaviour Game.Command
    end
  end

  use Networking.Socket
  use Game.Room

  @doc """
  Parse a string to turn into a command tuple
  """
  @spec parse(command :: String.t) :: t
  def parse(command) do
    case command do
      "e" -> {Game.Command.Move, [:east]}
      "east" -> {Game.Command.Move, [:east]}
      "global " <> message -> {Game.Command.Global, [message]}
      "help " <> topic -> {Game.Command.Help, [topic |> String.downcase]}
      "help" -> {Game.Command.Help, []}
      "inventory" -> {Game.Command.Inventory, []}
      "inv" -> {Game.Command.Inventory, []}
      "look" -> {Game.Command.Look, []}
      "look " <> object -> {Game.Command.Look, [object]}
      "n" -> {Game.Command.Move, [:north]}
      "north" -> {Game.Command.Move, [:north]}
      "quit" -> {Game.Command.Quit, []}
      "s" -> {Game.Command.Move, [:south]}
      "say " <> message -> {Game.Command.Say, [message]}
      "south" -> {Game.Command.Move, [:south]}
      "w" -> {Game.Command.Move, [:west]}
      "west" -> {Game.Command.Move, [:west]}
      "who" <> _extra -> {Game.Command.Who, []}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:error, :bad_parse}, _session, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
    :ok
  end
  def run({module, args}, session, state) do
    module.run(args, session, state)
  end
end
