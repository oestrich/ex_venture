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
    case Agent.get(__MODULE__, &(Map.get(&1, name, nil))) do
      nil ->
        value = Config.find_config(name)
        Agent.update(__MODULE__, &(Map.put(&1, name, value)))
        value
      value ->
        value
    end
  end

  def regen_tick_count(default) do
    case find_config("regen_tick_count") do
      nil -> default
      regen_tick_count -> regen_tick_count |> Integer.parse() |> elem(0)
    end
  end
end
