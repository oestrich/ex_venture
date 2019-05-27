defmodule Game.Command.Config do
  @moduledoc """
  The "config" command
  """

  use Game.Command

  alias Data.Save.Config, as: PlayerConfig
  alias Game.Format.Players, as: FormatPlayers
  alias Game.Player
  alias Game.Session.GMCP

  commands(["config"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Config"
  def help(:short), do: "View your config of the game"

  def help(:full) do
    """
    The {command}config{/command} command lets you view and set your player configuration options.

    You can change the following options:

      {white}hints{/white}:
        A true/false option to show hints in the game, use {command}config [on|off]{/command}

      {white}pager_size{/white}:
        The amount of lines that should be returned in a single page for a
        paginated response. Default is 20 lines.

      {white}prompt{/white}:
        A string that is formatted to display your prompt, use {command}config set{/command}. See more
        about prompts at {command}help prompt{/command}.

      {white}regen_notifications{/white}:
        A true/false option that will show regeneration notifications, use {command}config [on|off]{/command}

      {white}color_[color]{/white}:
        Replace {white}[color]{/white} with a color tag from the {command}color tags{/command} list. You can set via
        {command}config set color_npc blue{/command} for instance. You can reset your colors with {command}color reset{/command}.

    View a list of configuration options
    [ ] > {command}config{/command}

    Turn a config on:
    [ ] > {command}config on hints{/command}

    Turn a config off:
    [ ] > {command}config off hints{/command}

    Set a config:
    [ ] > {command}config set prompt %h/%Hhp{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Config.parse("config")
      {:list}

      iex> Game.Command.Config.parse("config on hints")
      {:on, "hints"}

      iex> Game.Command.Config.parse("config off hints")
      {:off, "hints"}

      iex> Game.Command.Config.parse("config set prompt %h/%Hhp")
      {:set, "prompt %h/%Hhp"}

      iex> Game.Command.Config.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("config"), do: {:list}
  def parse("config on " <> config), do: {:on, config}
  def parse("config off " <> config), do: {:off, config}
  def parse("config set " <> config), do: {:set, config}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({:list}, state = %{save: save}) do
    {:paginate, FormatPlayers.config(save), state}
  end

  def run({:on, config_name}, state) do
    case is_config?(config_name) do
      true ->
        case PlayerConfig.settable?(config_name) do
          true ->
            message =
              "Cannot turn on #{config_name}. See {command}help config{/command} for more information."

            state |> Socket.echo(message)

          false ->
            update_config(config_name, true, state)
        end

      false ->
        message = "Unknown configuration option, \"#{config_name}\"."
        state |> Socket.echo(message)
    end
  end

  def run({:off, config_name}, state) do
    case is_config?(config_name) do
      true ->
        case PlayerConfig.settable?(config_name) do
          true ->
            message =
              "Cannot turn off #{config_name}. See {command}help config{/command} for more information."

            state |> Socket.echo(message)

          false ->
            update_config(config_name, false, state)
        end

      false ->
        message = "Unknown configuration option, \"#{config_name}\"."
        state |> Socket.echo(message)
    end
  end

  def run({:set, config}, state) do
    [config_name | value] = String.split(config)
    value = Enum.join(value, " ")

    case is_config?(config_name) do
      true ->
        case PlayerConfig.settable?(config_name) do
          true ->
            cast_and_set_config(config_name, value, state)

          false ->
            message =
              "Cannot set {white}#{config_name}{/white} directly. See {command}help config{/command} for more information."

            state |> Socket.echo(message)
        end

      false ->
        message = "Unknown configuration option, \"#{config_name}\"."
        state |> Socket.echo(message)
    end
  end

  defp is_config?(config_name), do: PlayerConfig.option?(config_name)

  defp cast_and_set_config(config_name, value, state) do
    case PlayerConfig.cast_config(config_name, value) do
      {:ok, value} ->
        update_config(config_name, value, state)

      :error ->
        message = "There was a problem saving your config, it appears to be in the wrong format."
        state |> Socket.echo(message)

      {:error, :bad_config} ->
        message = "There was a problem saving your config, this config cannot be set."
        state |> Socket.echo(message)
    end
  end

  defp update_config(config_name, value, state = %{save: save}) do
    config_atom =
      config_name
      |> String.downcase()
      |> String.to_atom()

    config =
      save.config
      |> Map.put(config_atom, value)

    state = Player.update_save(state, %{save | config: config})

    case value do
      true ->
        message = "{white}%{config_name}{/white} is turned on."
        state |> Socket.echo(message)

      false ->
        message = "{white}${config_name}{/white} is turned off."
        state |> Socket.echo(message)

      string when is_binary(string) ->
        message = "{white}#{config_name}{/white} is set to \"#{string}\"."
        state |> Socket.echo(message)

      integer when is_integer(integer) ->
        message = "{white}#{config_name}{/white} is set to \"#{integer}\"."
        state |> Socket.echo(message)
    end

    state |> push_config(config)

    {:update, state}
  end

  @doc """
  Push config to the network and client layer
  """
  @spec push_config(State.t(), map()) :: :ok
  def push_config(state, config) do
    state |> Socket.set_config(config)
    state |> GMCP.config(config)
    :ok
  end
end
