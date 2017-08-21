defmodule Game.Config do
  @moduledoc """
  Hold Config to not query as often
  """

  alias Data.Config

  @doc false
  def start_link() do
    Agent.start_link(fn () -> %{} end, name: __MODULE__)
  end

  def find_config(name) do
    Agent.get_and_update(__MODULE__, fn (config) ->
      case Map.get(config, name, nil) do
        nil ->
          value = Config.find_config(name)
          {value, Map.put(config, name, value)}
        value -> {value, config}
      end
    end)
  end

  def regen_health(default) do
    case find_config("regen_health") do
      nil -> default
      regen_health -> regen_health |> Integer.parse() |> elem(0)
    end
  end

  def regen_skill_points(default) do
    case find_config("regen_skill_points") do
      nil -> default
      regen_skill_points -> regen_skill_points |> Integer.parse() |> elem(0)
    end
  end
end
