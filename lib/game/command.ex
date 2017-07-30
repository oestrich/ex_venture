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
      @before_compile Game.Command

      @short_help ""
      @full_help ""

      @commands []
      @aliases []
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def commands(), do: @commands

      @doc false
      def aliases(), do: @aliases

      @doc false
      def help() do
        %{
          short: @short_help,
          full: @full_help,
        }
      end

      def parse(command) do
        Game.Command.parse_command(__MODULE__, command)
      end

      def run(_, _, %{socket: socket}) do
        socket |> @socket.echo("Unknown command")
        :ok
      end
    end
  end

  use Networking.Socket
  use Game.Room

  alias Game.Command

  @commands [
    Command.Global, Command.Help, Command.Info, Command.Inventory, Command.Look,
    Command.Move, Command.PickUp, Command.Quit, Command.Say, Command.Who, Command.Wield,
  ]

  @doc """
  Get all commands that `use Command`
  """
  @spec commands() :: [atom]
  def commands(), do: @commands

  @doc """
  Parse a string to turn into a command tuple
  """
  @spec parse(command :: String.t) :: t
  def parse(command) do
    commands()
    |> Enum.find(fn (module) ->
      alias_found = module.aliases
      |> Enum.any?(fn (alias_cmd) ->
        # match an alias only if it's by itself or it won't match another similar command
        # eg 'w' matching for 'west'
        Regex.match?(~r(^#{alias_cmd}$), command) || Regex.match?(~r(^#{alias_cmd}[^\w]), command)
      end)

      command_found = module.commands
      |> Enum.any?(fn (cmd) ->
        Regex.match?(~r(^#{cmd}), command)
      end)

      command_found || alias_found
    end)
    |> _parse(command)
  end

  @doc """
  Parse a command

  Uses the module's commands and aliases to find the arguments

      iex> Game.Command.parse_command(Game.Command.Who, "who")
      []

      iex> Game.Command.parse_command(Game.Command.Say, "say hi")
      ["hi"]
  """
  @spec parse_command(module :: atom, command :: String.t) :: [String.t]
  def parse_command(module, command) do
    argument = (module.commands ++ module.aliases)
    |> Enum.reduce(command, fn (cmd, command) ->
      String.replace_prefix(command, cmd, "") |> String.trim
    end)

    case argument do
      "" -> []
      argument -> [argument]
    end
  end

  defp _parse(nil, _), do: {:error, :bad_parse}
  defp _parse(module, command) do
    arguments = module.parse(command)
    {module, arguments}
  end

  def run({:error, :bad_parse}, _session, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
    :ok
  end
  def run({module, args}, session, state) do
    module.run(args, session, state)
  end
end
