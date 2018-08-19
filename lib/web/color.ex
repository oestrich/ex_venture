defmodule Web.Color do
  @moduledoc """
  Interface to the game color module
  """

  alias Game.ColorCodes
  alias Game.Config
  alias Web.ColorCode

  @cache_key :web

  @doc """
  Get the latest version of the css
  """
  @spec latest_version() :: integer()
  def latest_version() do
    case Cachex.get(@cache_key, :latest_version) do
      {:ok, version} when version != nil ->
        version

      _ ->
        codes = ColorCode.all()
        config = configured_colors()

        case codes ++ config do
          [] ->
            Timex.now() |> Timex.to_unix()

          all ->
            all
            |> Enum.map(&(&1.updated_at |> Timex.to_unix()))
            |> Enum.max()
            |> set_latest_version()
        end
    end
  end

  defp configured_colors() do
    Config.color_config()
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.map(&Web.Config.find_config/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Set the latest version of the css, to clear caches
  """
  @spec set_latest_version(integer()) :: integer()
  def set_latest_version(version) do
    Cachex.put(@cache_key, :latest_version, version)
    version
  end

  @doc """
  Get the options for basic colors
  """
  @spec options() :: {String.t(), String.t()}
  def options() do
    Data.Color.options()
    |> Enum.map(fn color ->
      {String.capitalize(color), color}
    end)
  end

  @doc """
  Get all color keys available for use in the game
  """
  def color_keys() do
    basic_keys = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    custom_keys = Enum.map(ColorCode.all(), & &1.key)
    basic_keys ++ custom_keys
  end

  @doc """
  Format a string for HTML colors, wrapping in span tags
  """
  def format(string) do
    string
    |> String.replace("{black}", "<span class='black'>")
    |> String.replace("{red}", "<span class='red'>")
    |> String.replace("{green}", "<span class='green'>")
    |> String.replace("{yellow}", "<span class='yellow'>")
    |> String.replace("{blue}", "<span class='blue'>")
    |> String.replace("{magenta}", "<span class='magenta'>")
    |> String.replace("{cyan}", "<span class='cyan'>")
    |> String.replace("{white}", "<span class='white'>")
    |> String.replace("{map:blue}", "<span class='map-blue'>")
    |> String.replace("{map:brown}", "<span class='map-brown'>")
    |> String.replace("{map:dark-green}", "<span class='map-dark-green'>")
    |> String.replace("{map:green}", "<span class='map-green'>")
    |> String.replace("{map:grey}", "<span class='map-grey'>")
    |> String.replace("{map:light-grey}", "<span class='map-light-grey'>")
    |> String.replace("{npc}", "<span class='yellow'>")
    |> String.replace("{item}", "<span class='cyan'>")
    |> String.replace("{player}", "<span class='blue'>")
    |> String.replace("{skill}", "<span class='white'>")
    |> String.replace("{quest}", "<span class='yellow'>")
    |> String.replace("{room}", "<span class='green'>")
    |> String.replace("{say}", "<span class='green'>")
    |> String.replace("{command}", "<span class='white'>")
    |> String.replace(~r/{command send='.*'}/, "<span class='white'>")
    |> String.replace("{command click=false}", "<span class='white'>")
    |> String.replace("{link}", "<span class='white'>")
    |> String.replace("{exit}", "<span class='white'>")
    |> String.replace("{shop}", "<span class='magenta'>")
    |> custom_colors()
    |> String.replace(~r/{\/[\w:-]+}/, "</span>")
  end

  defp custom_colors(string) do
    Game.Color.color_regex()
    |> Regex.split(string, include_captures: true)
    |> Enum.map(&replace_color_code/1)
    |> Enum.join()
  end

  defp replace_color_code("{/" <> code), do: "{/#{code}"

  defp replace_color_code("{" <> code) do
    key = code |> String.replace("}", "")

    case ColorCodes.get(key) do
      {:ok, color_code} ->
        "<span class='color-code-#{color_code.key}'>"

      {:error, :not_found} ->
        "<span>"
    end
  end

  defp replace_color_code(string), do: string

  @doc """
  Update color configuration
  """
  @spec update(map()) :: :ok
  def update(params) do
    keys =
      Config.color_config()
      |> Map.keys()
      |> Enum.map(&to_string/1)

    params
    |> Map.take(keys)
    |> Enum.each(fn {key, value} ->
      Web.Config.update(key, value)
    end)

    set_latest_version(Timex.now() |> Timex.to_unix())

    :ok
  end

  @doc """
  Clear configuration for colors
  """
  @spec reset() :: :ok
  def reset() do
    Config.color_config()
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.each(fn key ->
      Web.Config.clear(key)
    end)

    set_latest_version(Timex.now() |> Timex.to_unix())

    :ok
  end

  @doc """
  Convert a hex color string to rgb values
  """
  def hex_to_rgb(<<"#", red::binary-size(2), green::binary-size(2), blue::binary-size(2)>>) do
    <<red>> = Base.decode16!(String.upcase(red))
    <<green>> = Base.decode16!(String.upcase(green))
    <<blue>> = Base.decode16!(String.upcase(blue))

    %{red: red, green: green, blue: blue}
  end
end
