defmodule Game.Format do
  alias Data.Room

  alias Data.User
  alias Data.Save

  def global_say(user, message) do
    ~s({red}[global]{/red} #{say(user, message)})
  end

  @doc """
  Format the user's prompt
  """
  @spec prompt(user :: User.t, save :: Save.t) :: String.t
  def prompt(user, _save) do
    "\n[#{user.username}] > "
  end

  def say(user, message) do
    ~s[{blue}#{user.username}{/blue} says, {green}"#{message}"{/green}]
  end

  def room(room) do
    """
{green}#{room.name}{/green}
#{underline(room.name)}
#{room.description |> String.split() |> wrap() |> String.strip()}\n
Exits: #{exits(room)}
Players: #{players(room)}
    """
    |> String.strip
  end

  defp underline(string) do
    (1..(String.length(string) + 4))
    |> Enum.map(fn (_) -> "-" end)
    |> Enum.join("")
  end

  defp wrap(words, line \\ "", string \\ "")
  defp wrap([], line, string), do: "#{string}\n#{line}"
  defp wrap([word | left], line, string) do
    case String.length("#{line} #{word}") do
      len when len < 80 -> wrap(left, "#{line} #{word}", string)
      _ -> wrap(left, word, "#{string}\n#{line}")
    end
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
