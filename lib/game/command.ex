defmodule Game.Command do
  @moduledoc """
  Parses and runs commands from players
  """

  defstruct [text: "", module: nil, args: {}, system: false, continue: false, parsed_in: nil, ran_in: nil]

  @typedoc """
  A tuple with the first element being the command to run

  Example:

      {Game.Command.Run, "Hi there"}
  """
  @type t :: {module :: atom(), args :: []}

  @doc """
  Parse a command into arguments

  Should return `{:error, :bad_parse, command}` on a failed parse.
  """
  @callback parse(command :: String.t) :: tuple() | {:error, :bad_parse, command :: String.t}

  @doc """
  Run a command

  Returns `:ok` or `{:update, new_state}` and the Session server will accept the new state.
  """
  @callback run(args :: list, session :: pid, state :: map) :: :ok | {:update, state :: map}

  defmacro __using__(_opts) do
    quote do
      use Networking.Socket
      use Game.Room

      import Game.Command, only: [command: 1, command: 2]

      require Logger

      alias Game.Format
      alias Game.Message
      alias Game.Session

      Module.register_attribute __MODULE__, :commands, accumulate: true
      Module.register_attribute __MODULE__, :aliases, accumulate: true

      @behaviour Game.Command
      @before_compile Game.Command

      @help true
      @help_topic __MODULE__ |> to_string |> String.split(".") |> List.last
      @short_help ""
      @full_help ""

      @custom_parse false

      @must_be_alive false
    end
  end

  @doc """
  Register a command.

  You _must_ use the attribute `@custom_parse` before calling this macro if the command
  is going to define it's own parser. Otherwise this macro will define parse functions
  that will match first.

  Examples:

      command "look", aliases: ["l"]
      command "up", aliases: ["u"]
  """
  defmacro command(command, opts \\ []) do
    aliases = Keyword.get(opts, :aliases, [])

    quote do
      unquote(Enum.map(aliases, &alias_parse/1))

      @commands unquote(command)
      if !@custom_parse do
        def parse(unquote(command)), do: {}
        def parse(unquote(command) <> " " <> str), do: {str}

        def parse(unquote(String.capitalize(command))), do: {}
        def parse(unquote(String.capitalize(command)) <> " " <> str), do: {str}
      end
    end
  end

  defp alias_parse(command_alias) do
    quote do
      @aliases unquote(command_alias)
      if !@custom_parse do
        def parse(unquote(command_alias)), do: {}
        def parse(unquote(command_alias) <> " " <> str), do: {str}

        def parse(unquote(String.capitalize(command_alias))), do: {}
        def parse(unquote(String.capitalize(command_alias)) <> " " <> str), do: {str}
      end
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
      def custom_parse?(), do: @custom_parse

      @doc false
      def must_be_alive?(), do: @must_be_alive

      @doc false
      def has_help?(), do: @help

      @doc false
      def help() do
        %{
          topic: @help_topic,
          short: @short_help,
          full: @full_help,
        }
      end

      # Provide a default bad parse
      def parse(command), do: {:error, :bad_parse, command}
    end
  end

  defmodule Editor do
    @moduledoc """
    Editor callback

    If a command requires an editor, it should `use` this module and follow the callbacks.
    """

    @callback editor({:text, String.t}, state :: map) :: {:update, state :: map}
    @callback editor(:complete, state :: map) :: {:update, state :: map}

    defmacro __using__(_opts) do
      quote do
        @behaviour Game.Command.Editor
      end
    end
  end

  use Networking.Socket
  use Game.Room

  require Logger

  alias Data.User
  alias Game.Command
  alias Game.Insight
  alias Metrics.CommandInstrumenter

  @commands [
    # Put the more often used commands at the top and loosely sorted
    Command.Move,
    Command.Channels,
    Command.Say,
    Command.Look,
    Command.Target,
    Command.Skills,
    Command.Run,
    Command.Info,
    Command.Inventory,

    # Alphabetical
    Command.Bug,
    Command.Drop,
    Command.Emote,
    Command.Equipment,
    Command.Examine,
    Command.Help,
    Command.Map,
    Command.Mistake,
    Command.PickUp,
    Command.Quit,
    Command.Shops,
    Command.Tell,
    Command.Version,
    Command.Wear,
    Command.Who,
    Command.Wield,
  ]

  @doc """
  Get all commands that `use Command`
  """
  @spec commands() :: [atom]
  def commands(), do: @commands

  @doc """
  Parse a string to turn into a command tuple
  """
  @spec parse(command :: String.t, user :: User.t) :: t
  def parse(command, user)
  def parse("", _user), do: {:skip, {}}
  def parse(command, %{class: class}) do
    start_parsing_at = Timex.now()
    command = command |> String.replace(~r/  /, " ")
    class_skill = class.skills |> Enum.find(&(class_parse_command(&1, command)))
    case class_skill do
      nil ->
        command
        |> _parse()
        |> maybe_bad_parse(command)
        |> record_parse_time(start_parsing_at)
      _ ->
        %__MODULE__{text: command, module: Game.Command.Skills, args: {class_skill, command}}
        |> record_parse_time(start_parsing_at)
    end
  end

  defp record_parse_time(command = %Command{}, start_parsing_at) do
    end_parsing_at = Timex.now()
    %{command | parsed_in: Timex.diff(end_parsing_at, start_parsing_at, :microseconds)}
  end
  defp record_parse_time(command, _start_parsing_at), do: command

  defp class_parse_command(skill, command) do
    Regex.match?(~r(^#{skill.command}), command)
  end

  defp _parse(command) do
    @commands
    |> Enum.find_value(fn (module) ->
      case module.parse(command) do
        {:error, :bad_parse, _} -> false
        arguments -> %__MODULE__{text: command, module: module, args: arguments}
      end
    end)
  end

  # Capture no command found and return a bad parse
  defp maybe_bad_parse(nil, command), do: {:error, :bad_parse, command}
  defp maybe_bad_parse(command, _), do: command

  def run({:skip, {}}, _session, _state), do: :ok
  def run({:error, :bad_parse, command}, session, %{socket: socket}) do
    Insight.bad_command(command)
    Logger.info("Command for session #{inspect(session)} failed to parse #{inspect(command)}", type: :command)
    socket |> @socket.echo("Unknown command, type {white}help{/white} for assistance.")
    :ok
  end
  def run(command = %__MODULE__{module: module, args: args}, session, state = %{socket: socket}) do
    started_run_at = Timex.now()
    case module.must_be_alive? do
      true ->
        case state do
          %{save: %{stats: %{health: health}}} when health <= 0 ->
            socket |> @socket.echo("You are passed out and cannot perform this action.")
            :ok
          _ ->
            args
            |> module.run(session, state)
            |> log_command(command, session, started_run_at)
        end
      false ->
        args
        |> module.run(session, state)
        |> log_command(command, session, started_run_at)
    end
  end

  # Log the command and pass thru the value the command returned
  defp log_command(pass_thru, command = %Command{}, session, started_run_at) do
    ran_in = Timex.diff(Timex.now(), started_run_at, :microseconds)
    command = %{command | ran_in: ran_in}
    CommandInstrumenter.command_run(session, command)
    pass_thru
  end
end
