defmodule Game.Config do
  @moduledoc """
  Hold Config to not query as often
  """

  alias Data.Config
  alias Data.Save

  @doc false
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Reload a config from the database
  """
  @spec reload(String.t()) :: any()
  def reload(name) do
    value = Config.find_config(name)
    Agent.update(__MODULE__, &Map.put(&1, name, value))
    value
  end

  def find_config(name) do
    case Agent.get(__MODULE__, &Map.get(&1, name, nil)) do
      nil -> reload(name)
      value -> value
    end
  end

  def host() do
    ExVenture.config(Application.get_env(:ex_venture, :networking)[:host])
  end

  def port() do
    ExVenture.config(Application.get_env(:ex_venture, :networking)[:port])
  end

  def ssl?(), do: ssl_port() != nil

  def ssl_port() do
    port = Keyword.get(Application.get_env(:ex_venture, :networking), :ssl_port, nil)
    ExVenture.config(port)
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
  Message after signing into the game

  Used during sign in
  """
  def after_sign_in_message(default \\ "") do
    case find_config("after_sign_in_message") do
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
      nil ->
        nil

      save ->
        {:ok, save} = Save.load(Poison.decode!(save))
        save
    end
  end

  @doc """
  Starting prompt
  """
  @spec default_prompt() :: String.t()
  def default_prompt(), do: "%h/%Hhp %s/%Ssp %m/%Mmv %xxp"
end
