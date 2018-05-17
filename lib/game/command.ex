defmodule Game.Command do
  @moduledoc """
  Parses and runs commands from players
  """

  defstruct text: "",
            module: nil,
            args: {},
            system: false,
            continue: false,
            parsed_in: nil,
            ran_in: nil

  @typedoc """
  A tuple with the first element being the command to run

  Example:

      {Game.Command.Run, "Hi there"}
  """
  @type t :: {atom(), []}

  @doc """
  Help text.

  `type` argument will be one of: `:topic`, `:short`, `:full`

  Example:

      def help(:topic), do: "Who"
      def help(:short), do: "See who is online"
      def help(:full) do
        "Full help text"
      end
  """
  @callback help(type :: atom()) :: Keyword.t()

  @doc """
  Parse a command into arguments

  Should return `{:error, :bad_parse, command}` on a failed parse.
  """
  @callback parse(command :: String.t()) :: tuple() | {:error, :bad_parse, command :: String.t()}

  @doc """
  Run a command

  Returns `:ok` or `{:update, new_state}` and the Session server will accept the new state.
  """
  @callback run(args :: list, state :: map) :: :ok | {:update, state :: map}

  @doc """
  Sets up the basic command module. A short cut for `use Game.Command.Macro`.
  """
  defmacro __using__(_opts) do
    quote do
      use Game.Command.Macro
    end
  end

  use Networking.Socket
  use Game.Room

  require Logger

  alias Data.User
  alias Game.Command
  alias Game.Command.Skills
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
    Command.AFK,
    Command.Bug,
    Command.Colors,
    Command.Config,
    Command.Crash,
    Command.Debug,
    Command.Drop,
    Command.Emote,
    Command.Equipment,
    Command.Examine,
    Command.Give,
    Command.Greet,
    Command.Help,
    Command.Hone,
    Command.Listen,
    Command.Mail,
    Command.Map,
    Command.Mistake,
    Command.PickUp,
    Command.Quest,
    Command.Quit,
    Command.Recall,
    Command.Scan,
    Command.Shops,
    Command.Tell,
    Command.Train,
    Command.Typo,
    Command.Use,
    Command.Version,
    Command.Wear,
    Command.Whisper,
    Command.Who,
    Command.Wield,

    # Socials are last
    Command.Socials
  ]

  @doc """
  Get all commands that `use Command`
  """
  @spec commands() :: [atom()]
  def commands(), do: @commands

  @doc """
  Parse a string to turn into a command tuple
  """
  @spec parse(String.t(), User.t()) :: t()
  def parse(command, user)
  def parse("", _user), do: {:skip, {}}

  def parse(command, user) do
    start_parsing_at = Timex.now()
    command = command |> String.replace(~r/  /, " ")
    skill_parse = command |> Skills.parse_skill(user)

    case skill_parse do
      {:error, :bad_parse, _} ->
        command
        |> _parse()
        |> maybe_bad_parse(command)
        |> record_parse_time(start_parsing_at)

      _ ->
        skill_parse
        |> record_parse_time(start_parsing_at)
    end
  end

  defp record_parse_time(command = %Command{}, start_parsing_at) do
    end_parsing_at = Timex.now()
    %{command | parsed_in: Timex.diff(end_parsing_at, start_parsing_at, :microseconds)}
  end

  defp record_parse_time(command, _start_parsing_at), do: command

  defp _parse(command) do
    @commands
    |> Enum.find_value(fn module ->
      case module.parse(command) do
        {:error, :bad_parse, _} -> false
        arguments -> %__MODULE__{text: command, module: module, args: arguments}
      end
    end)
  end

  # Capture no command found and return a bad parse
  defp maybe_bad_parse(nil, command), do: {:error, :bad_parse, command}
  defp maybe_bad_parse(command, _), do: command

  @doc """
  Run a command after parsing
  """
  @spec run({atom(), tuple()}, State.t()) :: :ok
  def run({:skip, {}}, _state), do: :ok

  def run({:error, :bad_parse, command}, %{socket: socket}) do
    Insight.bad_command(command)

    Logger.info(
      "Command for session #{inspect(self())} failed to parse #{inspect(command)}",
      type: :command
    )

    socket |> @socket.echo("Unknown command, type {command}help{/command} for assistance.")
    :ok
  end

  def run(command = %__MODULE__{module: module, args: args}, state = %{socket: socket}) do
    started_run_at = Timex.now()

    case module.must_be_alive? do
      true ->
        case state do
          %{save: %{stats: %{health_points: health_points}}} when health_points <= 0 ->
            socket |> @socket.echo("You are passed out and cannot perform this action.")
            :ok

          _ ->
            args
            |> module.run(state)
            |> log_command(command, started_run_at)
        end

      false ->
        args
        |> module.run(state)
        |> log_command(command, started_run_at)
    end
  end

  # Log the command and pass thru the value the command returned
  defp log_command(pass_thru, command = %Command{}, started_run_at) do
    ran_in = Timex.diff(Timex.now(), started_run_at, :microseconds)
    command = %{command | ran_in: ran_in}
    CommandInstrumenter.command_run(self(), command)
    pass_thru
  end
end
