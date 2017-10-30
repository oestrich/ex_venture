defmodule Game.Format do
  @moduledoc """
  Format data into strings to send to the connected player
  """

  use Game.Currency

  alias Data.Class
  alias Data.Exit
  alias Data.Item
  alias Data.Room
  alias Data.User
  alias Data.Save
  alias Data.Skill
  alias Game.Format.Table
  alias Game.Door

  @doc """
  Format a channel message

  Example:

      iex> Game.Format.channel_say("global", {:npc, %{name: "NPC"}}, "Hello")
      ~s({red}[global]{/red} {yellow}NPC{/yellow} says, {green}"Hello"{/green})
  """
  @spec channel_say(channel :: String.t, sender :: {atom, map}, message :: String.t) :: String.t
  def channel_say(channel, sender, message) do
    ~s({red}[#{channel}]{/red} #{say(sender, message)})
  end

  @doc """
  Format the user's prompt

  Example:

      iex> class = %{points_abbreviation: "SP"}
      iex> stats = %{health: 50, max_health: 75, skill_points: 9, max_skill_points: 10, move_points: 4, max_move_points: 10}
      iex> Game.Format.prompt(%{name: "user", class: class}, %{experience_points: 1010, stats: stats})
      "[50/75hp 9/10sp 4/10mv 10xp] > "
  """
  @spec prompt(user :: User.t, save :: Save.t) :: String.t
  def prompt(user, save)
  def prompt(%{class: class}, %{experience_points: exp, stats: stats}) do
    sp = class.points_abbreviation |> String.downcase
    exp = rem(exp, 1000)

    health = "#{stats.health}/#{stats.max_health}hp"
    skill = "#{stats.skill_points}/#{stats.max_skill_points}#{sp}"
    move = "#{stats.move_points}/#{stats.max_move_points}mv"

    "[#{health} #{skill} #{move} #{exp}xp] > "
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
  Format a tell message

      iex> Game.Format.tell(%{name: "Player"}, "secret message")
      ~s[{blue}Player{/blue} tells you, {green}"secret message"{/green}]
  """
  def tell(%{name: name}, message) do
    ~s[{blue}#{name}{/blue} tells you, {green}"#{message}"{/green}]
  end

  @doc """
  Format an emote message

  Example:

      iex> Game.Format.emote({:npc, %{name: "NPC"}}, "does something")
      ~s[{yellow}NPC{/yellow} {green}does something{/green}]

      iex> Game.Format.emote({:user, %{name: "Player"}}, "does something")
      ~s[{blue}Player{/blue} {green}does something{/green}]
  """
  @spec emote(sender :: map, message :: String.t) :: String.t
  def emote({:npc, %{name: name}}, emote) do
    ~s[{yellow}#{name}{/yellow} {green}#{emote}{/green}]
  end
  def emote({:user, %{name: name}}, emote) do
    ~s[{blue}#{name}{/blue} {green}#{emote}{/green}]
  end

  @doc """
  Format full text for a room
  """
  @spec room(room :: Game.Room.t, map :: String.t) :: String.t
  def room(room, map) do
    """
{green}#{room.name}{/green}
#{underline(room.name)}
#{room.description |> wrap()}\n
#{map}

#{who_is_here(room)}
Exits: #{exits(room)}
Items: #{items(room)}
#{shops(room)}
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
  def underline(nil), do: ""
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
    |> Enum.map(fn (direction) ->
      case Exit.exit_to(room, direction) do
        %{id: exit_id, has_door: true} ->
          "{white}#{direction} (#{Door.get(exit_id)}){/white}"
        _ ->
          "{white}#{direction}{/white}"
      end
    end)
    |> Enum.join(", ")
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

  def items(room = %{items: items}) when is_list(items) do
    items = items |> Enum.map(fn (item) -> "{cyan}#{item.name}{/cyan}" end)

    items ++ [currency(room)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end
  def items(_), do: ""

  @doc """
  Format currency
  """
  @spec currency(Save.t | Room.t) :: String.t
  def currency(%{currency: currency}) when currency == 0, do: ""
  def currency(%{currency: currency}), do: "{cyan}#{currency} #{@currency}{/cyan}"

  @doc """
  Format Shop text for shops in the room

  Example:

      iex> Game.Format.shops(%{shops: [%{name: "Hole in the Wall"}]})
      "Shops: {magenta}Hole in the Wall{/magenta}"

      iex> Game.Format.shops(%{shops: [%{name: "Hole in the Wall"}]}, label: false)
      "  - {magenta}Hole in the Wall{/magenta}"
  """
  @spec shops(room :: Game.Room.t) :: String.t
  def shops(room, opts \\ [])
  def shops(%{shops: []}, _opts), do: ""
  def shops(%{shops: shops}, [label: false]) do
    shops
    |> Enum.map(fn (shop) -> "  - {magenta}#{shop.name}{/magenta}" end)
    |> Enum.join(", ")
  end
  def shops(%{shops: shops}, _) do
    shops = shops
    |> Enum.map(fn (shop) -> "{magenta}#{shop.name}{/magenta}" end)
    |> Enum.join(", ")
    "Shops: #{shops}"
  end
  def shops(_, _), do: ""

  def list_shop(shop, items), do: Game.Format.Shop.list(shop, items)

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
  """
  @spec inventory(currency :: integer, wearing :: map, wielding :: map, items :: [Item.t]) :: String.t
  def inventory(currency, wearing, wielding, items) do
    items = items
    |> Enum.map(fn (item) -> "  - {cyan}#{item.name}{/cyan}" end)
    |> Enum.join("\n")

    """
    #{equipment(wearing, wielding)}
    You are holding:
    #{items}
    You have #{currency} #{@currency}.
    """ |> String.trim
  end

  @doc """
  Format your equipment

  Example:

      iex> wearing = %{chest: %{name: "Leather Armor"}}
      iex> wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      iex> Game.Format.equipment(wearing, wielding)
      "You are wearing:\\n  - {cyan}Leather Armor{/cyan} on your chest\\nYou are wielding:\\n  - a {cyan}Shield{/cyan} in your left hand\\n  - a {cyan}Short Sword{/cyan} in your right hand"
  """
  @spec equipment(wearing :: map, wielding :: map) :: String.t
  def equipment(wearing, wielding) do
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

    ["You are wearing:", wearing, "You are wielding:", wielding]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  @doc """
  Format your info sheet
  """
  @spec info(user :: User.t) :: String.t
  def info(user = %{save: save}) do
    %{stats: stats} = save

    rows = [
      ["Level", save.level],
      ["XP", save.experience_points],
      ["Health", "#{stats.health}/#{stats.max_health}"],
      [user.class.points_name, "#{stats.skill_points}/#{stats.max_skill_points}"],
      ["Movement", "#{stats.move_points}/#{stats.max_move_points}"],
      ["Strength", stats.strength],
      ["Intelligence", stats.intelligence],
      ["Dexterity", stats.dexterity],
      ["Play Time", play_time(user.seconds_online)],
    ]

    Table.format("#{user.name} - #{user.race.name} - #{user.class.name}", rows, [12, 15])
  end

  @doc """
  Format skills

      iex> skills = [%{level: 1, name: "Slash", points: 2, command: "slash", description: "Fight your foe"}]
      iex> Game.Format.skills(%{name: "Fighter", points_abbreviation: "PP", skills: skills})
      "Fighter\\n\\nLevel - Name - Points - Description\\n1 - Slash (slash) - 2PP - Fight your foe\\n"
  """
  @spec skills(class :: Class.t) :: String.t
  def skills(class)
  def skills(%{name: name, points_abbreviation: points_abbreviation, skills: skills}) do
    skills = skills
    |> Enum.map(&(skill(&1, points_abbreviation)))
    |> Enum.join("\n")

    """
    #{name}

    Level - Name - Points - Description
    #{skills}
    """
  end

  @doc """
  Format a skill

      iex> skill = %{level: 1, name: "Slash", points: 2, command: "slash", description: "Fight your foe"}
      iex> Game.Format.skill(skill, "PP")
      "1 - Slash (slash) - 2PP - Fight your foe"
  """
  @spec skill(skill :: Skill.t, sp_name :: String.t) :: String.t
  def skill(skill, sp_name) do
    "#{skill.level} - #{skill.name} (#{skill.command}) - #{skill.points}#{sp_name} - #{skill.description}"
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

  def name(who), do: target_name(who)

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

  @doc """
  Format number of seconds online into a human readable string

      iex> Game.Format.play_time(125)
      "00h 02m 05s"

      iex> Game.Format.play_time(600)
      "00h 10m 00s"

      iex> Game.Format.play_time(3670)
      "01h 01m 10s"

      iex> Game.Format.play_time(36700)
      "10h 11m 40s"
  """
  @spec play_time(seconds :: integer) :: String.t
  def play_time(seconds) do
    hours = seconds |> div(3600) |> to_string |> String.pad_leading(2, "0")
    minutes = seconds |> div(60) |> rem(60) |> to_string |> String.pad_leading(2, "0")
    seconds = seconds |> rem(60) |> to_string |> String.pad_leading(2, "0")

    "#{hours}h #{minutes}m #{seconds}s"
  end

  @doc """
  An item was dropped message

      iex> Game.Format.dropped({:npc, %{name: "NPC"}}, %{name: "Sword"})
      "{yellow}NPC{/yellow} dropped a Sword."

      iex> Game.Format.dropped({:user, %{name: "Player"}}, %{name: "Sword"})
      "{blue}Player{/blue} dropped a Sword."

      iex> Game.Format.dropped({:user, %{name: "Player"}}, {:currency, 100})
      "{blue}Player{/blue} dropped 100 gold."
  """
  @spec dropped(who :: {tuple, map}, item :: Item.t) :: String.t
  def dropped(who, {:currency, amount}) do
    "#{name(who)} dropped #{amount} #{currency()}."
  end
  def dropped(who, item) do
    "#{name(who)} dropped a #{item.name}."
  end
end
