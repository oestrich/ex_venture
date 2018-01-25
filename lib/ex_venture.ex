defmodule ExVenture do
  @moduledoc """
  """

  @doc """
  Helper function for loading system environment variables in configuration
  """
  @spec config({:system, String.t()} | any) :: any
  def config({:system, name}), do: System.get_env(name)
  def config(value), do: value

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
