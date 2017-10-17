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

      @help_topic __MODULE__ |> to_string |> String.split(".") |> List.last
      @short_help ""
      @full_help ""

      @commands []
      @aliases []

      @custom_parse false

      @must_be_alive false
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
      def help() do
        %{
          topic: @help_topic,
          short: @short_help,
          full: @full_help,
        }
      end

      def run(_command, session, state) do
        Game.Command.run({:error, :bad_parse, "bad parse"}, session, state)
      end
    end
  end

  use Networking.Socket
  use Game.Room

  require Logger

  alias Data.User
  alias Game.Command
  alias Game.Insight

  @commands [
    Command.Channels, Command.Help, Command.Info, Command.Inventory, Command.Look,
    Command.Move, Command.PickUp, Command.Quit, Command.Say, Command.Who, Command.Wield,
    Command.Wear, Command.Target, Command.Skills, Command.Emote, Command.Map, Command.Examine,
    Command.Tell, Command.Equipment, Command.Drop, Command.Shops, Command.Run,
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
    builtin = commands() |> Enum.find(&(module_parse_command(&1, command)))
    case class_skill do
      nil ->
        builtin
        |> _parse(command)
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

  defp module_parse_command(module, command) do
    alias_found = module.aliases
    |> Enum.any?(fn (alias_cmd) ->
      # match an alias only if it's by itself or it won't match another similar command
      # eg 'w' matching for 'west'
      Regex.match?(~r(^#{alias_cmd}$)i, command) || Regex.match?(~r(^#{alias_cmd}[^\w]), command)
    end)

    command_found = module.commands
    |> Enum.any?(fn (cmd) ->
      Regex.match?(~r(^#{cmd})i, command)
    end)

    command_found || alias_found
  end

  @doc """
  Parse a command

  Uses the module's commands and aliases to find the arguments

      iex> Game.Command.parse_command(Game.Command.Who, "who")
      {}

      iex> Game.Command.parse_command(Game.Command.Say, "say hi")
      {"hi"}
  """
  @spec parse_command(module :: atom, command :: String.t) :: [String.t]
  def parse_command(module, command) do
    argument = (module.commands ++ module.aliases)
    |> Enum.reduce(command, fn (cmd, command) ->
      command
      |> String.replace(~r/^#{cmd}/i, "")
      |> String.trim
    end)

    case argument do
      "" -> {}
      argument -> {argument}
    end
  end

  defp _parse(nil, command), do: {:error, :bad_parse, command}
  defp _parse(module, command) do
    case module.custom_parse? do
      true ->
        arguments = module.parse(command)
        %__MODULE__{text: command, module: module, args: arguments}
      false ->
        arguments = parse_command(module, command)
        %__MODULE__{text: command, module: module, args: arguments}
    end
  end

  def run({:skip, {}}, _session, _state), do: :ok
  def run({:error, :bad_parse, command}, _session, %{socket: socket}) do
    Insight.bad_command(command)
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
            module.run(args, session, state)
            |> log_command(command, session, started_run_at)
        end
      false ->
        module.run(args, session, state)
        |> log_command(command, session, started_run_at)
    end
  end

  # Log the command and pass thru the value the command returned
  defp log_command(pass_thru, command = %Command{}, session, started_run_at) do
    ran_in = Timex.diff(Timex.now(), started_run_at, :microseconds)
    command = %{command | ran_in: ran_in}

    Logger.info "Command for session #{inspect(session)} [text=\"#{command.text}\", module=#{command.module}, system=#{command.system}, continue=#{command.continue}, parsed_in=#{command.parsed_in}μs, ran_in=#{command.ran_in}μs]"

    pass_thru
  end
end
