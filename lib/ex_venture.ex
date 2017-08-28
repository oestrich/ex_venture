defmodule ExVenture do
  @moduledoc """
  """

  @doc """
  Helper function for loading system environment variables in configuration
  """
  @spec config(configuration :: {:system, String.t} | any) :: any
  def config({:system, name}), do: System.get_env(name)
  def config(value), do: value
end
