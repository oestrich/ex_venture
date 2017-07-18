defmodule Game.Format do
  alias Data.Room

  def global_say(user, message) do
    ~s({red}[global]{/red} #{say(user, message)})
  end

  def say(user, message) do
    ~s[{blue}#{user.username}{/blue} says, {green}"#{message}"{/green}]
  end

  def room(room) do
    """
{green}#{room.name}{/green}
#{room.description}
Exits: #{exits(room)}
Players: #{players(room)}
    """
  end

  defp exits(room) do
    Room.exits(room)
    |> Enum.map(fn (direction) -> "{white}#{direction}{/white}" end)
    |> Enum.join(" ")
  end

  def players(%{players: players}) do
    players
    |> Enum.map(fn (player) -> "{blue}#{player.username}{/blue}" end)
    |> Enum.join(", ")
  end
end
