defmodule ExVenture do
  @moduledoc false

  @doc """
  Helper function for loading system environment variables in configuration
  """
  @spec config({:system, String.t()} | {:system, String.t(), any()} | any()) :: any()
  def config({:system, name}), do: System.get_env(name)
  def config({:system, name, default}) do
    System.get_env(name) || default
  end
  def config(value), do: value

  @doc """
  Cast a configuration value into an integer
  """
  def config_integer(value) do
    case config(value) do
      value when is_integer(value) ->
        value

      value when is_binary(value) ->
        String.to_integer(value)
    end
  end

  @doc """
  Find the version of ExVenture that is running
  """
  @spec version() :: String.t()
  def version() do
    ex_venture =
      :application.loaded_applications()
      |> Enum.find(&(elem(&1, 0) == :ex_venture))

    "ExVenture v#{elem(ex_venture, 2)}"
  end
end
