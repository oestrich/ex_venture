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
#{room.description |> wrap()}\n
#{who_is_here(room)}
Exits: #{exits(room)}
    """
    |> String.strip
  end

  @doc """
  Create an 'underline'

  Example:

      iex> Game.Format.underline("Room Name")
      "-------------"
  """
  def underline(string) do
    (1..(String.length(string) + 4))
    |> Enum.map(fn (_) -> "-" end)
    |> Enum.join("")
  end

  @doc """
  Wraps lines of text
  """
  @spec wrap(string :: String.t) :: String.t
  def wrap(string) do
    string
    |> String.split()
    |> _wrap()
  end

  defp _wrap(words, line \\ "", string \\ "")
  defp _wrap([], line, string), do: join(string, line, "\n")
  defp _wrap([word | left], line, string) do
    case String.length("#{line} #{word}") do
      len when len < 80 -> _wrap(left, join(line, word, " "), string)
      _ -> _wrap(left, word, join(string, line, "\n"))
    end
  end

  defp join(str1, str2, joiner) do
    Enum.join([str1, str2] |> Enum.reject(&(&1 == "")), joiner)
  end

  defp exits(room) do
    Room.exits(room)
    |> Enum.map(fn (direction) -> "{white}#{direction}{/white}" end)
    |> Enum.join(" ")
  end

  def who_is_here(room) do
    [players(room), npcs(room)]
    |> Enum.reject(fn (line) -> line == "" end)
    |> Enum.join(" ")
  end

  def players(%{players: players}) do
    players
    |> Enum.map(fn (player) -> "{blue}#{player.username}{/blue} is here." end)
    |> Enum.join(" ")
  end
  def players(_), do: ""

  def npcs(%{npcs: npcs}) do
    npcs
    |> Enum.map(fn (npc) -> "{yellow}#{npc.name}{/yellow} is here." end)
    |> Enum.join(" ")
  end
  def npcs(_), do: ""
end
