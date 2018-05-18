defmodule Game.Format.Who do
  @moduledoc """
  Format the who list
  """

  alias Game.Format

  @doc """
  Format the player line in the who list
  """
  def player_line(player, metadata) do
    [
      player_stats(player),
      Format.player_name(player),
      Format.player_flags(player, none: false),
      afk(metadata),
    ] |> Enum.join(" ")
  end

  defp player_stats(player) do
    Enum.join([
      "[",
      String.pad_leading(Integer.to_string(player.save.level), 3),
      pad_and_limit(player.class.name),
      pad_and_limit(player.race.name),
      "]"
    ])
  end

  defp pad_and_limit(name) do
    String.slice(String.pad_leading(name, 10), 0, 10)
  end

  defp afk(%{is_afk: true}), do: "AFK"
  defp afk(_), do: ""
end
