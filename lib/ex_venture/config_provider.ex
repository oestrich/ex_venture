defmodule ExVenture.ConfigProvider do
  @moduledoc """
  Config provider for production

  Loads runtime configuration for the application
  """

  @behaviour Config.Provider

  # Let's pass the path to the JSON file as config
  @impl true
  def init(path) when is_binary(path), do: path

  @impl true
  def load(config, path) do
    Config.Reader.merge(config, Config.Reader.read!(path))
  end
end
