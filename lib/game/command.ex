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
          short: @short_help,
          full: @full_help,
        }
      end

      def run(_, session, state) do
        Game.Command.run({:error, :bad_parse}, session, state)
      end
    end
  end

  use Networking.Socket
  use Game.Room

  alias Data.User
  alias Game.Command

  @commands [
    Command.Global, Command.Help, Command.Info, Command.Inventory, Command.Look,
    Command.Move, Command.PickUp, Command.Quit, Command.Say, Command.Who, Command.Wield,
    Command.Wear, Command.Target, Command.Skills, Command.Emote, Command.Map, Command.Examine,
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
  def parse(command, %{class: class}) do
    class_skill = class.skills |> Enum.find(&(class_parse_command(&1, command)))
    builtin = commands() |> Enum.find(&(module_parse_command(&1, command)))
    case class_skill do
      nil ->
        builtin |> _parse(command)
      _ ->
        {Game.Command.Skills, {class_skill, command}}
    end
  end

  defp class_parse_command(skill, command) do
    Regex.match?(~r(^#{skill.command}), command)
  end

  defp module_parse_command(module, command) do
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
      |> String.replace_prefix(cmd, "")
      |> String.trim
    end)

    case argument do
      "" -> {}
      argument -> {argument}
    end
  end

  defp _parse(nil, _), do: {:error, :bad_parse}
  defp _parse(module, command) do
    case module.custom_parse? do
      true ->
        arguments = module.parse(command)
        {module, arguments}
      false ->
        arguments = parse_command(module, command)
        {module, arguments}
    end
  end

  def run({:error, :bad_parse}, _session, %{socket: socket}) do
    socket |> @socket.echo("Unknown command, type {white}help{/white} for assistance.")
    :ok
  end
  def run({module, args}, session, state = %{socket: socket}) do
    case module.must_be_alive? do
      true ->
        case state do
          %{save: %{stats: %{health: health}}} when health <= 0 ->
            socket |> @socket.echo("You are passed out and cannot perform this action.")
            :ok
          _ ->
            module.run(args, session, state)
        end
      false ->
        module.run(args, session, state)
    end
  end
end
