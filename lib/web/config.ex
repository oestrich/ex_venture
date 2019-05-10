defmodule Web.Config do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Config
  alias Data.Repo
  alias Game.Config, as: GameConfig

  @doc """
  Get a config by name
  """
  @spec get(String.t()) :: Config.t()
  def get(name), do: find_config(name)

  @doc """
  Get a changeset for an new page
  """
  @spec new(String.t()) :: map()
  def new(name), do: %Config{name: name} |> Config.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Config.t()) :: map()
  def edit(config), do: config |> Config.changeset(%{})

  @doc """
  Get a config struct by name
  """
  @spec find_config(String.t()) :: Config.t()
  def find_config(name) do
    Config
    |> where([c], c.name == ^name)
    |> Repo.one()
  end

  @doc """
  Update and reload a configuration
  """
  @spec update(String.t(), String.t()) :: {:ok, Config.t()}
  def update(name, value) do
    case find_config(name) do
      nil ->
        _create(name, value)

      config ->
        _update(config, name, value)
    end
  end

  defp _create(name, value) do
    %Data.Config{}
    |> Config.changeset(%{name: name, value: value})
    |> Repo.insert()
  end

  defp _update(config, _name, value) do
    config
    |> Config.changeset(%{value: value})
    |> Repo.update()
  end

  @doc """
  Update and reload a configuration
  """
  @spec clear(String.t()) :: {:ok, Config.t()}
  def clear(name) do
    case find_config(name) do
      nil ->
        :ok

      config ->
        Repo.delete(config)
        GameConfig.reload(name)

        :ok
    end
  end
end
