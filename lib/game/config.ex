defmodule Game.Config do
  @moduledoc """
  Hold Config to not query as often
  """

  alias Data.Config
  alias Data.Repo
  alias Data.Save
  alias Data.Stats

  @color_config %{
    color_background: "#002b36",
    color_text_color: "#93a1a1",
    color_panel_border: "#073642",
    color_character_info_background: "#073642",
    color_character_info_text: "#93a1a1",
    color_room_info_background: "#073642",
    color_room_info_text: "#93a1a1",
    color_room_info_exit: "#93a1a1",
    color_stat_block_background: "#eee8d5",
    color_health_bar: "#dc322f",
    color_health_bar_background: "#fdf6e3",
    color_skill_bar: "#859900",
    color_skill_bar_background: "#fdf6e3",
    color_move_bar: "#268bd2",
    color_move_bar_background: "#fdf6e3",
    color_black: "#003541",
    color_red: "#dc322f",
    color_green: "#859900",
    color_yellow: "#b58900",
    color_blue: "#268bd2",
    color_magenta: "#d33682",
    color_cyan: "#2aa198",
    color_white: "#eee8d5",
    color_map_blue: "#005fd7",
    color_map_brown: "#875f00",
    color_map_dark_green: "#005f00",
    color_map_green: "#00af00",
    color_map_grey: "#9e9e9e",
    color_map_light_grey: "#d0d0d0"
  }

  @basic_stats %{
    health_points: 50,
    max_health_points: 50,
    skill_points: 50,
    max_skill_points: 50,
    move_points: 20,
    max_move_points: 20,
    strength: 10,
    dexterity: 10,
    constitution: 10,
    intelligence: 10,
    wisdom: 10,
  }

  @doc false
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def color_config(), do: @color_config

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
      nil ->
        reload(name)

      value ->
        value
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

  @doc """
  Number of "ticks" before regeneration occurs
  """
  @spec regen_tick_count(Integer.t()) :: Integer.t()
  def regen_tick_count(default) do
    case find_config("regen_tick_count") do
      nil ->
        default

      regen_tick_count ->
        regen_tick_count |> Integer.parse() |> elem(0)
    end
  end

  @doc """
  The Game's name

  Used in web page titles
  """
  @spec game_name(String.t()) :: String.t()
  def game_name(default \\ "ExVenture") do
    case find_config("game_name") do
      nil ->
        default

      game_name ->
        game_name
    end
  end

  @doc """
  Message of the Day

  Used during sign in
  """
  @spec motd(String.t()) :: String.t()
  def motd(default) do
    case find_config("motd") do
      nil ->
        default

      motd ->
        motd
    end
  end

  @doc """
  Message after signing into the game

  Used during sign in
  """
  @spec after_sign_in_message(String.t()) :: String.t()
  def after_sign_in_message(default \\ "") do
    case find_config("after_sign_in_message") do
      nil ->
        default

      motd ->
        motd
    end
  end

  @doc """
  Starting save

  Which room, etc the player will start out with
  """
  @spec starting_save() :: map()
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
  Your pool of random character names to offer to players signing up
  """
  @spec character_names() :: [String.t()]
  def character_names() do
    case find_config("character_names") do
      nil ->
        []

      names ->
        names
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
    end
  end

  @doc """
  Pick a random set of 5 names
  """
  @spec random_character_names() :: [String.t()]
  def random_character_names() do
    character_names()
    |> Enum.shuffle()
    |> Enum.take(5)
  end

  @doc """
  Remove a name from the list of character names if it was used
  """
  @spec claim_character_name(String.t()) :: :ok
  def claim_character_name(name) do
    case name in character_names() do
      true ->
        _claim_character_name(name)

      false ->
        :ok
    end
  end

  defp _claim_character_name(name) do
    case Repo.get_by(Config, name: "character_names") do
      nil ->
        :ok

      config ->
        names = List.delete(character_names(), name)
        changeset = config |> Config.changeset(%{value: Enum.join(names, "\n")})
        Repo.update(changeset)
        reload("character_names")
    end
  end

  @doc """
  Load the game's basic stats
  """
  @spec basic_stats() :: map()
  def basic_stats() do
    case find_config("basic_stats") do
      nil ->
        @basic_stats

      stats ->
        {:ok, stats} = Stats.load(Poison.decode!(stats))
        stats
    end
  end

  Enum.each(@color_config, fn {config, default} ->
    def unquote(config)() do
      case find_config(to_string(unquote(config))) do
        nil ->
          unquote(default)

        color ->
          color
      end
    end
  end)
end
