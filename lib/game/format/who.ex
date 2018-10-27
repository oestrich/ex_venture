defmodule Game.Format.Who do
  @moduledoc """
  Format the who list
  """

  alias Game.Format.Players, as: FormatPlayers

  @doc """
  Format the player line in the who list
  """
  def player_line(player, metadata) do
    [
      player_stats(player),
      FormatPlayers.player_name(player),
      FormatPlayers.player_flags(player.extra, none: false),
      afk(metadata)
    ]
    |> Enum.join(" ")
  end

  @doc """
  Format a remote player name
  """
  def remote_player_line(game_name, player_name) do
    player = %{name: "#{player_name}@#{game_name}"}

    " - #{FormatPlayers.player_name(player)}"
  end

  defp player_stats(player) do
    Enum.join([
      "[",
      String.pad_leading(Integer.to_string(player.extra.level), 3),
      pad_and_limit(player.extra.class),
      pad_and_limit(player.extra.race),
      "]"
    ])
  end

  defp pad_and_limit(name) do
    String.slice(String.pad_leading(name, 10), 0, 10)
  end

  defp afk(%{is_afk: true}), do: "AFK"
  defp afk(_), do: ""
end
