defmodule Game.Config do
  @moduledoc """
  Hold Config to not query as often
  """

  alias Data.Config
  alias Data.Save

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

  @doc """
  The Game's name

  Used in web page titles
  """
  def game_name(default \\ "ExVenture") do
    case find_config("game_name") do
      nil -> default
      game_name -> game_name
    end
  end

  @doc """
  Message of the Day

  Used during sign in
  """
  def motd(default) do
    case find_config("motd") do
      nil -> default
      motd -> motd
    end
  end

  @doc """
  Starting save

  Which room, etc the player will start out with
  """
  def starting_save() do
    case find_config("starting_save") do
      nil -> nil
      save ->
        {:ok, save} = Save.load(Poison.decode!(save))
        save
    end
  end
end
