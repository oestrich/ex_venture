defmodule Data.Save.Config do
  @moduledoc """
  Helpers for the player's configuration
  """

  alias Data.Color
  alias Game.ColorCodes

  @doc """
  Determine if a string is a configuration option
  """
  @spec option?(String.t() | atom()) :: boolean()
  def option?(config) do
    case to_string(config) do
      "prompt" -> true
      "hints" -> true
      "pager_size" -> true
      "regen_notifications" -> true
      config -> color_config?(config)
    end
  end

  @doc """
  Determine if a configuration option can be used via set
  """
  @spec settable?(String.t() | atom()) :: boolean()
  def settable?(config) do
    case to_string(config) do
      "prompt" -> true
      "pager_size" -> true
      config -> color_config?(config)
    end
  end

  @doc """
  Cast a configuration option if it is settable
  """
  @spec cast_config(String.t() | atom(), any()) :: any()
  def cast_config(config, value) do
    case to_string(config) do
      "prompt" ->
        {:ok, to_string(value)}

      "pager_size" ->
        Ecto.Type.cast(:integer, value)

      config ->
        maybe_cast_color(config, value)
    end
  end

  defp maybe_cast_color(config, value) do
    case color_config?(config) do
      true ->
        cast_color(value)

      false ->
        {:error, :bad_config}
    end
  end

  defp cast_color(value) do
    case is_a_color?(value) do
      true ->
        {:ok, value}

      false ->
        {:error, :bad_config}
    end
  end

  # NOTE: Eventually move this into the Game directory or get all of the caches living in
  # the data layer. This shouldn't really be reaching across boundaries.
  defp is_a_color?(value) do
    Enum.any?(Color.options(), &(&1 == value)) || Enum.any?(ColorCodes.all(), &(&1.key == value))
  end

  @doc """
  Starting prompt
  """
  @spec default_prompt() :: String.t()
  def default_prompt(), do: "%h/%Hhp %s/%Ssp %m/%Mmv %xxp"

  @doc """
  Check if a key is color configuration
  """
  def color_config?(key) do
    Color.color_tags()
    |> Enum.any?(fn tag ->
      "color_#{tag}" == to_string(key)
    end)
  end
end
