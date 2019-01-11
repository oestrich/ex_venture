defmodule Game.Command.Colors do
  @moduledoc """
  The "colors" command
  """

  use Game.Command

  alias Data.Color
  alias Data.Save.Config
  alias Game.ColorCodes
  alias Game.Command.Config, as: CommandConfig
  alias Game.Player

  commands([{"colors", ["color"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Colors"
  def help(:short), do: "View colors in the game"

  def help(:full) do
    """
    #{help(:short)}.

    View all colors, including map colors:
    [ ] > {command}colors{/command}

    View all color 'tags':
    [ ] > {command}color tags{/command}

    Reset your configured colors:
    [ ] > {command}colors reset{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Colors.parse("colors")
      {:list}

      iex> Game.Command.Colors.parse("color list")
      {:list}
      iex> Game.Command.Colors.parse("colors list")
      {:list}

      iex> Game.Command.Colors.parse("colors reset")
      {:reset}

      iex> Game.Command.Colors.parse("color tags")
      {:semantic}

      iex> Game.Command.Colors.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("colors"), do: {:list}
  def parse("colors list"), do: {:list}
  def parse("color list"), do: {:list}
  def parse("colors reset"), do: {:reset}
  def parse("color tags"), do: {:semantic}

  @impl Game.Command
  def run(command, state)

  def run({:list}, state) do
    message = """
    Colors
    #{Format.underline("Colors")}

    Base Colors:
    #{base_colors()}
    #{custom_colors()}

    Map Colors:
    #{map_colors()}
    """

    {:paginate, message, state}
  end

  def run({:reset}, state) do
    save = state.save

    config =
      save.config
      |> Enum.reject(fn {key, _val} ->
        Config.color_config?(key)
      end)
      |> Enum.into(%{})

    state = Player.update_save(state, %{save | config: config})

    state |> CommandConfig.push_config(config)
    state.socket |> @socket.echo(gettext("Your colors have been reset."))

    {:update, state}
  end

  def run({:semantic}, state) do
    message = """
    Color Tags
    #{Format.underline("Colors")}

    The available color tags are in the following list. You can configure these with
    the {command send='help config'}config{/command} command.

    #{color_tags()}
    """

    {:paginate, message, state}
  end

  defp base_colors() do
    Color.options()
    |> Enum.map(fn color ->
      "{#{color}}#{color}{/#{color}}"
    end)
    |> Enum.join("\n")
  end

  defp custom_colors() do
    ColorCodes.all()
    |> Enum.map(fn color_code ->
      "{#{color_code.key}}#{color_code.key}{/#{color_code.key}}"
    end)
    |> Enum.join("\n")
  end

  defp map_colors() do
    Color.map_colors()
    |> Enum.map(fn color ->
      "{#{color}}#{color}{/#{color}}"
    end)
    |> Enum.join("\n")
  end

  defp color_tags() do
    Color.color_tags()
    |> Enum.map(fn tag ->
      case tag do
        "command" ->
          "{#{tag} click=false}#{tag}{/#{tag}}"

        "exit" ->
          "{#{tag} click=false}#{tag}{/#{tag}}"

        "link" ->
          "{#{tag} click=false}#{tag}{/#{tag}}"

        _ ->
          "{#{tag}}#{tag}{/#{tag}}"
      end
    end)
    |> Enum.join("\n")
  end
end
