defmodule Game.Command.Config do
  @moduledoc """
  The "config" command
  """

  use Game.Command

  alias Data.Save.Config, as: PlayerConfig
  alias Game.Format

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
    {:paginate, Format.config(save), state}
  end

  def run({:on, config_name}, state) do
    case is_config?(config_name) do
      true ->
        update_config(config_name, true, state)

      false ->
        state.socket |> @socket.echo("Unknown configuration option, \"#{config_name}\"")
    end
  end

  def run({:off, config_name}, state) do
    case is_config?(config_name) do
      true ->
        update_config(config_name, false, state)

      false ->
        state.socket |> @socket.echo("Unknown configuration option, \"#{config_name}\"")
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
            state.socket
            |> @socket.echo(
              "Cannot set #{config_name} directly. See {command}help config{/command} for more information."
            )
        end

      false ->
        state.socket |> @socket.echo("Unknown configuration option, \"#{config_name}\"")
    end
  end

  defp is_config?(config_name), do: PlayerConfig.option?(config_name)

  defp cast_and_set_config(config_name, value, state) do
    case PlayerConfig.cast_config(config_name, value) do
      {:ok, value} ->
        update_config(config_name, value, state)

      :error ->
        state.socket
        |> @socket.echo(
          "There was a problem saving your config, it appears to be in the wrong format."
        )

      {:error, :bad_config} ->
        state.socket
        |> @socket.echo("There was a problem saving your config, this config cannot be set.")
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

    save = %{save | config: config}
    user = %{state.user | save: save}
    state = %{state | user: user, save: save}

    case value do
      true ->
        state.socket |> @socket.echo("#{config_name} is turned on")

      false ->
        state.socket |> @socket.echo("#{config_name} is turned off")

      string when is_binary(string) ->
        state.socket |> @socket.echo("#{config_name} is set to \"#{string}\"")

      integer when is_integer(integer) ->
        state.socket |> @socket.echo("#{config_name} is set to \"#{integer}\"")
    end

    {:update, state}
  end
end
