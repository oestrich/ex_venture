defmodule Game.Format do
  @moduledoc """
  Format data into strings to send to the connected player
  """

  alias Data.Class
  alias Data.Item
  alias Data.Room
  alias Data.User
  alias Data.Save
  alias Data.Skill

  @doc """
  Format a global channel message

  Example:

      iex> Game.Format.global_say({:npc, %{name: "NPC"}}, "Hello")
      ~s({red}[global]{/red} {yellow}NPC{/yellow} says, {green}"Hello"{/green})
  """
  @spec global_say(sender :: map, message :: String.t) :: String.t
  def global_say(sender, message) do
    ~s({red}[global]{/red} #{say(sender, message)})
  end

  @doc """
  Format the user's prompt

  Example:

      iex> class = %{points_abbreviation: "SP"}
      iex> stats = %{health: 50, max_health: 75, skill_points: 9, max_skill_points: 10}
      iex> Game.Format.prompt(%{name: "user", class: class}, %{stats: stats})
      "[50/75hp 9/10sp] > "
  """
  @spec prompt(user :: User.t, save :: Save.t) :: String.t
  def prompt(user, save)
  def prompt(%{class: class}, %{stats: stats}) do
    sp = class.points_abbreviation |> String.downcase
    "[#{stats.health}/#{stats.max_health}hp #{stats.skill_points}/#{stats.max_skill_points}#{sp}] > "
  end
  def prompt(_user, _save), do: "> "

  @doc """
  Format a say message

  Example:

      iex> Game.Format.say({:npc, %{name: "NPC"}}, "Hello")
      ~s[{yellow}NPC{/yellow} says, {green}"Hello"{/green}]

      iex> Game.Format.say({:user, %{name: "Player"}}, "Hello")
      ~s[{blue}Player{/blue} says, {green}"Hello"{/green}]
  """
  @spec say(sender :: map, message :: String.t) :: String.t
  def say({:npc, %{name: name}}, message) do
    ~s[{yellow}#{name}{/yellow} says, {green}"#{message}"{/green}]
  end
  def say({:user, %{name: name}}, message) do
    ~s[{blue}#{name}{/blue} says, {green}"#{message}"{/green}]
  end

  @doc """
  Format full text for a room
  """
  @spec room(room :: Game.Room.t) :: String.t
  def room(room) do
    """
{green}#{room.name}{/green}
#{underline(room.name)}
#{room.description |> wrap()}\n
#{who_is_here(room)}
Exits: #{exits(room)}
Items: #{items(room)}
    """
    |> String.trim
  end

  @doc """
  Peak at a room from the room you're in

  Example:

    iex> Game.Format.peak_room(%{name: "Hallway"}, "north")
    "{green}Hallway{/green} is north."
  """
  @spec peak_room(room :: Game.Room.t, direction :: String.t) :: String.t
  def peak_room(room, direction) do
    "{green}#{room.name}{/green} is #{direction}."
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
    |> _wrap("", "")
  end

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
    room
    |> Room.exits()
    |> Enum.map(fn (direction) -> "{white}#{direction}{/white}" end)
    |> Enum.join(" ")
  end

  @doc """
  Format full text for who is in the room

  Example:

      iex> Game.Format.who_is_here(%{players: [%{name: "Mordred"}], npcs: [%{name: "Arthur"}]})
      "{blue}Mordred{/blue} is here. {yellow}Arthur{/yellow} is here."
  """
  def who_is_here(room) do
    [players(room), npcs(room)]
    |> Enum.reject(fn (line) -> line == "" end)
    |> Enum.join(" ")
  end

  @doc """
  Format Player text for who is in the room

  Example:

      iex> Game.Format.players(%{players: [%{name: "Mordred"}, %{name: "Arthur"}]})
      "{blue}Mordred{/blue} is here. {blue}Arthur{/blue} is here."
  """
  @spec players(room :: Game.Room.t) :: String.t
  def players(%{players: players}) do
    players
    |> Enum.map(fn (player) -> "{blue}#{player.name}{/blue} is here." end)
    |> Enum.join(" ")
  end
  def players(_), do: ""

  @doc """
  Format NPC text for who is in the room

  Example:

      iex> Game.Format.npcs(%{npcs: [%{name: "Mordred"}, %{name: "Arthur"}]})
      "{yellow}Mordred{/yellow} is here. {yellow}Arthur{/yellow} is here."
  """
  @spec npcs(room :: Game.Room.t) :: String.t
  def npcs(%{npcs: npcs}) do
    npcs
    |> Enum.map(fn (npc) -> "{yellow}#{npc.name}{/yellow} is here." end)
    |> Enum.join(" ")
  end
  def npcs(_), do: ""

  def items(%{items: items}) when is_list(items) do
    items
    |> Enum.map(fn (item) -> "{cyan}#{item.name}{/cyan}" end)
    |> Enum.join(", ")
  end
  def items(_), do: ""

  @doc """
  Display an item

  Example:

      iex> string = Game.Format.item(%{name: "Short Sword", description: "A simple blade"})
      iex> Regex.match?(~r(Short Sword), string)
      true
  """
  @spec item(item :: Item.t) :: String.t
  def item(item) do
    """
    {cyan}#{item.name}{/cyan}
    #{item.name |> underline}
    #{item.description}
    #{item_stats(item)}
    """ |> String.trim
  end

  @doc """
  Format an items stats

      iex> Game.Format.item_stats(%{type: "armor", stats: %{slot: :chest}})
      "Slot: chest"

      iex> Game.Format.item_stats(%{type: "basic"})
      ""
  """
  @spec item_stats(Item.t) :: String.t
  def item_stats(item)
  def item_stats(%{type: "armor", stats: stats}) do
    "Slot: #{stats.slot}"
  end
  def item_stats(_), do: ""

  @doc """
  Format your inventory

  Example:

      iex> wearing = %{chest: %{name: "Leather Armor"}}
      iex> wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      iex> items = [%{name: "Potion"}, %{name: "Dagger"}]
      iex> Game.Format.inventory(wearing, wielding, items)
      "You are wearing:\\n  - {cyan}Leather Armor{/cyan} on your chest\\nYou are wielding:\\n  - a {cyan}Shield{/cyan} in your left hand\\n  - a {cyan}Short Sword{/cyan} in your right hand\\nYou are holding:\\n  - {cyan}Potion{/cyan}\\n  - {cyan}Dagger{/cyan}"
  """
  @spec inventory(wearing :: map, wielding :: map, items :: [Item.t]) :: String.t
  def inventory(wearing, wielding, items) do
    wearing = wearing
    |> Map.to_list
    |> Enum.sort_by(&(elem(&1, 0)))
    |> Enum.map(fn ({part, item}) -> "  - {cyan}#{item.name}{/cyan} on your #{part}" end)
    |> Enum.join("\n")

    wielding = wielding
    |> Map.to_list
    |> Enum.sort_by(&(elem(&1, 0)))
    |> Enum.map(fn ({hand, item}) -> "  - a {cyan}#{item.name}{/cyan} in your #{hand} hand" end)
    |> Enum.join("\n")

    items = items
    |> Enum.map(fn (item) -> "  - {cyan}#{item.name}{/cyan}" end)
    |> Enum.join("\n")

    "You are wearing:\n#{wearing}\nYou are wielding:\n#{wielding}\nYou are holding:\n#{items}"
  end

  @doc """
  Format your info sheet

  Example:

      iex> stats = %{health: 50, strength: 10, dexterity: 10}
      iex> Game.Format.info(%{name: "hero", save: %Data.Save{stats: stats}, class: %{name: "Fighter"}})
      "hero\\n--------\\nFighter\\n\\nHealth: 50\\nStrength: 10\\nDexterity: 10"
  """
  @spec info(user :: User.t) :: String.t
  def info(user = %{save: save}) do
    %{stats: stats} = save

    """
    #{user.name}
    #{underline(user.name)}
    #{user.class.name}

    Health: #{stats.health}
    Strength: #{stats.strength}
    Dexterity: #{stats.dexterity}
    """ |> String.trim
  end

  @doc """
  Format skills

      iex> skills = [%{name: "Slash", points: 2, command: "slash", description: "Fight your foe"}]
      iex> Game.Format.skills(%{name: "Fighter", points_abbreviation: "PP", skills: skills})
      "Fighter\\nSlash (slash) - 2PP - Fight your foe\\n"
  """
  @spec skills(class :: Class.t) :: String.t
  def skills(class)
  def skills(%{name: name, points_abbreviation: points_abbreviation, skills: skills}) do
    skills = skills |> Enum.map(&(skill(&1, points_abbreviation)))

    """
    #{name}
    #{skills}
    """
  end

  @doc """
  Format a skill

      iex> skill = %{name: "Slash", points: 2, command: "slash", description: "Fight your foe"}
      iex> Game.Format.skill(skill, "PP")
      "Slash (slash) - 2PP - Fight your foe"
  """
  @spec skill(skill :: Skill.t, sp_name :: String.t) :: String.t
  def skill(skill, sp_name) do
    "#{skill.name} (#{skill.command}) - #{skill.points}#{sp_name} - #{skill.description}"
  end

  @doc """
  Format a skill, from perspective of the user

      iex> Game.Format.skill_user(%{user_text: "Slash away"}, [], {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> effects = [%{kind: "damage", type: :slashing, amount: 10}]
      iex> Game.Format.skill_user(%{user_text: "You slash away at {target}"}, effects, {:npc, %{name: "Bandit"}})
      "You slash away at {yellow}Bandit{/yellow}\\n10 slashing damage is dealt."
  """
  def skill_user(skill, effects, target)
  def skill_user(%{user_text: user_text}, skill_effects, target) do
    user_text = user_text |> String.replace("{target}", target_name(target))
    [user_text | effects(skill_effects)] |> Enum.join("\n")
  end

  @doc """
  Format a skill, from the perspective of a usee

      iex> Game.Format.skill_usee(%{usee_text: "Slash away"}, [], {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> effects = [%{kind: "damage", type: :slashing, amount: 10}]
      iex> Game.Format.skill_usee(%{usee_text: "You were slashed at by {user}"}, effects, {:npc, %{name: "Bandit"}})
      "You were slashed at by {yellow}Bandit{/yellow}\\n10 slashing damage is dealt."
  """
  def skill_usee(skill, skill_effects, skill_user)
  def skill_usee(%{usee_text: usee_text}, skill_effects, skill_user) do
    skill_usee(usee_text, skill_effects, skill_user)
  end
  def skill_usee(usee_text, skill_effects, skill_user) do
    usee_text = usee_text |> String.replace("{user}", target_name(skill_user))
    [usee_text | effects(skill_effects)] |> Enum.join("\n")
  end

  @doc """
  Format a target name, blue for user, yellow for npc

    iex> Game.Format.target_name({:user, %{name: "Player"}})
    "{blue}Player{/blue}"

    iex> Game.Format.target_name({:npc, %{name: "Bandit"}})
    "{yellow}Bandit{/yellow}"
  """
  @spec target_name({atom, map}) :: String.t
  def target_name({:npc, npc}) do
    "{yellow}#{npc.name}{/yellow}"
  end
  def target_name({:user, user}) do
    "{blue}#{user.name}{/blue}"
  end

  @doc """
  Format effects for display.
  """
  def effects([]), do: []
  def effects([effect | remaining]) do
    case effect do
      %{kind: "damage"} ->
        ["#{effect.amount} #{effect.type} damage is dealt." | effects(remaining)]
      _ -> effects(remaining)
    end
  end
end
