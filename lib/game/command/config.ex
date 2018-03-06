defmodule Game.Command.Config do
  @moduledoc """
  The "config" command
  """

  use Game.Command

  alias Game.Format

  commands(["config"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Config"
  def help(:short), do: "View your config of the game"

  def help(:full) do
    """
    #{help(:short)}

    View a list of configuration options
    [ ] > {command}config{/command}

    Turn a config on:
    [ ] > {command}config on hints{/command}

    Turn a config off:
    [ ] > {command}config off hints{/command}
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

      iex> Game.Command.Config.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("config"), do: {:list}
  def parse("config on " <> config), do: {:on, config}
  def parse("config off " <> config), do: {:off, config}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({:list}, state = %{save: save}) do
    {:paginate, Format.config(save), state}
  end

  def run({:on, config_name}, state = %{save: save}) do
    case is_config?(config_name, save) do
      true ->
        {:update, update_config(config_name, true, state)}

      false ->
        state.socket |> @socket.echo("Unknown configuration option, \"#{config_name}\"")
    end
  end

  def run({:off, config_name}, state = %{save: save}) do
    case is_config?(config_name, save) do
      true ->
        {:update, update_config(config_name, false, state)}

      false ->
        state.socket |> @socket.echo("Unknown configuration option, \"#{config_name}\"")
    end
  end

  defp is_config?(config_name, save) do
    keys =
      save.config
      |> Map.keys()
      |> Enum.map(&to_string/1)

    Enum.member?(keys, String.downcase(config_name))
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

    config_name = config_name |> String.capitalize()

    case value do
      true ->
        state.socket |> @socket.echo("#{config_name} is turned on")
      false ->
        state.socket |> @socket.echo("#{config_name} is turned off")
    end

    state
  end
end
