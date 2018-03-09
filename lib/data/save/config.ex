defmodule Data.Save.Config do
  @moduledoc """
  Helpers for the player's configuration
  """

  @doc """
  Determine if a string is a configuration option
  """
  @spec option?(String.t() | atom()) :: boolean()
  def option?(config) do
    case to_string(config) do
      "prompt" -> true
      "hints" -> true
      _ -> false
    end
  end

  @doc """
  Determine if a configuration option can be used via set
  """
  @spec settable?(String.t() | atom()) :: boolean()
  def settable?(config) do
    case to_string(config) do
      "prompt" -> true
      _ -> false
    end
  end

  @doc """
  Starting prompt
  """
  @spec default_prompt() :: String.t()
  def default_prompt(), do: "%h/%Hhp %s/%Ssp %m/%Mmv %xxp"
end
