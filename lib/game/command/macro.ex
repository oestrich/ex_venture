defmodule Game.Command.Macro do
  @moduledoc """
  Macros for Commands.
  """

  defmacro __using__(_opts) do
    quote do
      use Networking.Socket
      use Game.Environment

      import Game.Command.Macro, only: [commands: 1, commands: 2, gettext: 1, gettext: 2]

      require Game.Gettext
      require Logger

      alias Game.Format
      alias Game.Message
      alias Game.Session

      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)

      @behaviour Game.Command
      @before_compile Game.Command.Macro

      @must_be_alive false
      @required_flags []

      defoverridable Game.Command
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
      def must_be_alive?(), do: @must_be_alive

      @doc false
      def required_flags(), do: @required_flags

      # Provide a default bad parse
      def parse(command), do: {:error, :bad_parse, command}
    end
  end

  @doc """
  Register commands.

  If a command has its own parser, use the option `parse: false` to not generate parse functions.

  Examples:

      commands(["look at", {"look", ["l"]}])
      commands(["north", "south"], parse: false)
  """
  defmacro commands(commands, opts \\ []) do
    parse = Keyword.get(opts, :parse, true)

    commands = Enum.map(commands, &expand_command(&1, parse))

    parse_two_func =
      if parse do
        quote do
          @impl true
          def parse(command, _context), do: parse(command)
        end
      end

    quote do
      unquote(commands)
      unquote(parse_two_func)
    end
  end

  defp expand_command({command, aliases}, parse) do
    aliases =
      Enum.map(aliases, fn command_alias ->
        parse_func =
          if parse do
            alias_parse(command_alias)
          end

        quote do
          @aliases unquote(command_alias)
          unquote(parse_func)
        end
      end)

    command = expand_command(command, parse)

    quote do
      unquote(command)
      unquote(aliases)
    end
  end

  defp expand_command(command, parse) do
    parse_func =
      if parse do
        command_parse(command)
      end

    quote do
      @commands unquote(command)
      unquote(parse_func)
    end
  end

  defp command_parse(command) do
    quote do
      @impl Game.Command
      def parse(unquote(command)), do: {}
      def parse(unquote(command) <> " " <> str), do: {str}

      def parse(unquote(String.capitalize(command))), do: {}
      def parse(unquote(String.capitalize(command)) <> " " <> str), do: {str}
    end
  end

  defp alias_parse(command_alias) do
    quote do
      @impl Game.Command
      def parse(unquote(command_alias)), do: {}
      def parse(unquote(command_alias) <> " " <> str), do: {str}

      def parse(unquote(String.capitalize(command_alias))), do: {}
      def parse(unquote(String.capitalize(command_alias)) <> " " <> str), do: {str}
    end
  end

  @doc """
  Short cut for commands to hit the `commands` domain for gettext
  """
  defmacro gettext(message) do
    quote do
      Game.Gettext.dgettext("commands", unquote(message))
    end
  end

  defmacro gettext(message, binding) do
    quote do
      Game.Gettext.dgettext("commands", unquote(message), unquote(binding))
    end
  end
end
