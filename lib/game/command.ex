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

  alias Game.Command

  @doc """
  Parse a string to turn into a command tuple
  """
  @spec parse(command :: String.t) :: t
  def parse(command) do
    case command do
      "e" -> {Command.Move, [:east]}
      "east" -> {Command.Move, [:east]}
      "global " <> message -> {Command.Global, [message]}
      "help " <> topic -> {Command.Help, [topic |> String.downcase]}
      "help" -> {Command.Help, []}
      "inventory" -> {Command.Inventory, []}
      "inv" -> {Command.Inventory, []}
      "look" -> {Command.Look, []}
      "look at " <> object -> {Command.Look, [object]}
      "look " <> object -> {Command.Look, [object]}
      "n" -> {Command.Move, [:north]}
      "north" -> {Command.Move, [:north]}
      "pick up " <> item -> {Command.PickUp, [item]}
      "quit" -> {Command.Quit, []}
      "s" -> {Command.Move, [:south]}
      "say " <> message -> {Command.Say, [message]}
      "south" -> {Command.Move, [:south]}
      "w" -> {Command.Move, [:west]}
      "west" -> {Command.Move, [:west]}
      "who" <> _extra -> {Command.Who, []}
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
