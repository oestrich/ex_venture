defmodule Game.Command.Colors do
  @moduledoc """
  The "colors" command
  """

  use Game.Command

  alias Game.Color
  alias Game.ColorCodes

  commands(["colors"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Colors"
  def help(:short), do: "View colors in the game"

  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {command}colors{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Colors.parse("colors")
      {:list}

      iex> Game.Command.Colors.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("colors"), do: {:list}

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
      "{map:#{color}}#{color}{/map:#{color}}"
    end)
    |> Enum.join("\n")
  end
end
