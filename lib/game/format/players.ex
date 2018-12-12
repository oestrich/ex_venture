defmodule Game.Format.Players do
  @moduledoc """
  Format functions related to players
  """

  import Game.Format.Context

  alias Data.Save
  alias Data.User
  alias Game.Color
  alias Game.Format
  alias Game.Format.Table

  @doc """
  Colorize a player's name
  """
  @spec player_name(User.t()) :: String.t()
  def player_name(player), do: "{player}#{player.name}{/player}"

  @doc """
  Format the player's prompt

  Example:

      iex> stats = %{health_points: 50, max_health_points: 75, skill_points: 9, max_skill_points: 10, endurance_points: 4, max_endurance_points: 10}
      ...> config = %{prompt: "%h/%Hhp %s/%Ssp %e/%Eep %xxp"}
      ...> Players.prompt(%{experience_points: 1010, stats: stats, config: config})
      "\\\\[50/75hp 9/10sp 4/10ep 10xp\\\\] > "
  """
  @spec prompt(Save.t()) :: String.t()
  def prompt(save)

  def prompt(%{experience_points: exp, stats: stats, config: config}) do
    exp = rem(exp, 1000)

    "\\[#{config.prompt}\\] > "
    |> String.replace("%h", to_string(stats.health_points))
    |> String.replace("%H", to_string(stats.max_health_points))
    |> String.replace("%s", to_string(stats.skill_points))
    |> String.replace("%S", to_string(stats.max_skill_points))
    |> String.replace("%e", to_string(stats.endurance_points))
    |> String.replace("%E", to_string(stats.max_endurance_points))
    |> String.replace("%x", to_string(exp))
  end

  def prompt(_save), do: "> "

  @doc """
  Look at a Player
  """
  @spec player_full(User.t()) :: String.t()
  def player_full(player) do
    context()
    |> assign(:name, player_name(player))
    |> Format.template("[name] is here.")
  end

  @doc """
  Format your info sheet
  """
  @spec info(Character.t()) :: String.t()
  def info(character = %{save: save}) do
    %{stats: stats} = save

    rows = [
      ["Level", save.level],
      ["XP", save.experience_points],
      ["Spent XP", save.spent_experience_points],
      ["Health Points", "#{stats.health_points}/#{stats.max_health_points}"],
      ["Skill Points", "#{stats.skill_points}/#{stats.max_skill_points}"],
      ["Stamina Points", "#{stats.endurance_points}/#{stats.max_endurance_points}"],
      ["Strength", stats.strength],
      ["Agility", stats.agility],
      ["Intelligence", stats.intelligence],
      ["Awareness", stats.awareness],
      ["Vitality", stats.vitality],
      ["Willpower", stats.willpower],
      ["Play Time", play_time(character.seconds_online)]
    ]

    Table.format(
      "#{player_name(character)} - #{character.race.name} - #{character.class.name}",
      rows,
      [16, 15]
    )
  end

  @doc """
  View information about another player
  """
  def short_info(player = %{save: save}) do
    rows = [
      ["Level", save.level],
      ["Flags", player_flags(player)]
    ]

    Table.format("#{player_name(player)} - #{player.race.name} - #{player.class.name}", rows, [
      12,
      15
    ])
  end

  @doc """
  Format player flags

      iex> Players.player_flags(%{flags: ["admin"]})
      "{red}(Admin){/red}"

      iex> Players.player_flags(%{flags: []})
      "none"
  """
  def player_flags(player, opts \\ [none: true])
  def player_flags(%{flags: []}, none: true), do: "none"
  def player_flags(%{flags: []}, none: false), do: ""

  def player_flags(%{flags: flags}, _opts) do
    flags
    |> Enum.map(fn flag ->
      "{red}(#{String.capitalize(flag)}){/red}"
    end)
    |> Enum.join(" ")
  end

  @doc """
  Format number of seconds online into a human readable string

      iex> Players.play_time(125)
      "00h 02m 05s"

      iex> Players.play_time(600)
      "00h 10m 00s"

      iex> Players.play_time(3670)
      "01h 01m 10s"

      iex> Players.play_time(36700)
      "10h 11m 40s"
  """
  @spec play_time(integer()) :: String.t()
  def play_time(seconds) do
    hours = seconds |> div(3600) |> to_string |> String.pad_leading(2, "0")
    minutes = seconds |> div(60) |> rem(60) |> to_string |> String.pad_leading(2, "0")
    seconds = seconds |> rem(60) |> to_string |> String.pad_leading(2, "0")

    "#{hours}h #{minutes}m #{seconds}s"
  end

  @doc """
  Format the player's config
  """
  @spec config(Save.t()) :: String.t()
  def config(save) do
    rows =
      save.config
      |> Enum.map(fn {key, value} ->
        [to_string(key), value]
      end)

    rows = [["Name", "Value"] | rows]

    max_size =
      rows
      |> Enum.map(fn row ->
        row
        |> Enum.at(1)
        |> to_string()
        |> Color.strip_color()
        |> String.length()
      end)
      |> Enum.max()

    Table.format("Config", rows, [20, max_size])
  end
end
