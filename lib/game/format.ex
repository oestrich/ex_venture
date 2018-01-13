defmodule Game.Format do
  @moduledoc """
  Format data into strings to send to the connected player
  """

  use Game.Currency

  alias Data.Class
  alias Data.Exit
  alias Data.Item
  alias Data.Mail
  alias Data.Room
  alias Data.User
  alias Data.Save
  alias Data.Skill
  alias Game.Color
  alias Game.Format.Table
  alias Game.Door

  @doc """
  Template a string

      iex> Game.Format.template("{name} says hello", %{name: "Player"})
      "Player says hello"
  """
  def template(string, map) do
    map
    |> Enum.reduce(string, fn ({key, val}, string) ->
      String.replace(string, "{#{key}}", val)
    end)
  end

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

      iex> Game.Format.tell({:user, %{name: "Player"}}, "secret message")
      ~s[{blue}Player{/blue} tells you, {green}"secret message"{/green}]
  """
  def tell(sender, message) do
    ~s[#{name(sender)} tells you, {green}"#{message}"{/green}]
  end

  @doc """
  Format a tell message, for display of the sender

      iex> Game.Format.send_tell({:user, %{name: "Player"}}, "secret message")
      ~s[You tell {blue}Player{/blue}, {green}"secret message"{/green}]
  """
  def send_tell(character, message) do
    ~s[You tell #{name(character)}, {green}"#{message}"{/green}]
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
  @spec room(room :: Game.Room.t, items :: [Item.t], map :: String.t) :: String.t
  def room(room, items, map) do
    """
{green}#{room.name}{/green}
#{underline(room.name)}
#{room.description |> wrap()}\n
#{map}

#{who_is_here(room)}
#{maybe_exits(room)}#{maybe_items(room, items)}#{shops(room)}
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

      iex> Game.Format.underline("{blue}Player{/blue}")
      "----------"
  """
  def underline(nil), do: ""
  def underline(string) do
    (1..(String.length(Color.strip_color(string)) + 4))
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
    test_line = "#{line} #{word}" |> Color.strip_color()
    case String.length(test_line) do
      len when len < 80 -> _wrap(left, join(line, word, " "), string)
      _ -> _wrap(left, word, join(string, line, "\n"))
    end
  end

  defp join(str1, str2, joiner) do
    Enum.join([str1, str2] |> Enum.reject(&(&1 == "")), joiner)
  end

  defp maybe_exits(room) do
    case room |> Room.exits() do
      [] -> ""
      _ ->
        "Exits: #{exits(room)}\n"
    end
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

      iex> Game.Format.who_is_here(%{players: [%{name: "Mordred"}], npcs: [%{name: "Arthur", status_line: "{name} is here."}]})
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
  Look at a Player
  """
  @spec player_full(User.t()) :: String.t()
  def player_full(user) do
    "{name} is here."
    |> template(%{name: player_name(user)})
  end

  @doc """
  Format NPC text for who is in the room

  Example:

      iex> Game.Format.npcs(%{npcs: [%{name: "Mordred", status_line: "{name} is in the room."}, %{name: "Arthur", status_line: "{name} is here."}]})
      "{yellow}Mordred{/yellow} is in the room. {yellow}Arthur{/yellow} is here."
  """
  @spec npcs(room :: Game.Room.t) :: String.t
  def npcs(%{npcs: npcs}) do
    npcs
    |> Enum.map(&npc_status/1)
    |> Enum.join(" ")
  end
  def npcs(_), do: ""

  @doc """
  The status of an NPC
  """
  def npc_status(npc) do
    template(npc.status_line, %{name: npc_name(npc)})
  end

  @doc """
  Look at an NPC
  """
  @spec npc_full(Npc.t()) :: String.t()
  def npc_full(npc) do
    npc.description
    |> template(%{name: npc_name(npc), status_line: npc_status(npc)})
  end

  def maybe_items(_room, []), do: ""
  def maybe_items(room, items) do
    "Items: #{items(room, items)}\n"
  end

  def items(room, items) when is_list(items) do
    items = items |> Enum.map(&item_name/1)

    items ++ [currency(room)]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end
  def items(_, _), do: ""

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
      "Shops: {magenta}Hole in the Wall{/magenta}\\n"

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
    "Shops: #{shops}\n"
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
    #{item |> item_name()}
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
    items =
      items
      |> Enum.map(fn
        (%{item: item, quantity: 1}) -> "  - #{item_name(item)}"
        (%{item: item, quantity: quantity}) -> "  - {cyan}#{item.name} x#{quantity}{/cyan}"
      end)
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
    |> Enum.map(fn ({part, item}) -> "  - #{item_name(item)} on your #{part}" end)
    |> Enum.join("\n")

    wielding = wielding
    |> Map.to_list
    |> Enum.sort_by(&(elem(&1, 0)))
    |> Enum.map(fn ({hand, item}) -> "  - a #{item_name(item)} in your #{hand} hand" end)
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
      ["Dexterity", stats.dexterity],
      ["Intelligence", stats.intelligence],
      ["Wisdom", stats.wisdom],
      ["Play Time", play_time(user.seconds_online)],
    ]

    Table.format("#{user.name} - #{user.race.name} - #{user.class.name}", rows, [12, 15])
  end

  @doc """
  Format skills

      iex> skills = [%{level: 1, name: "Slash", points: 2, command: "slash", description: "Fight your foe"}]
      iex> Game.Format.skills(%{name: "Fighter", points_abbreviation: "PP"}, skills)
      "Fighter\\n\\nLevel - Name - Points - Description\\n1 - Slash (slash) - 2PP - Fight your foe\\n"
  """
  @spec skills(class :: Class.t, skills :: []) :: String.t
  def skills(class, skills)
  def skills(%{name: name, points_abbreviation: points_abbreviation}, skills) do
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

      iex> Game.Format.skill_usee(%{usee_text: "Slash away"}, user: {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> Game.Format.skill_usee(%{usee_text: "You were slashed at by {user}"}, user: {:npc, %{name: "Bandit"}})
      "You were slashed at by {yellow}Bandit{/yellow}"
  """
  def skill_usee(skill, opts \\ [])
  def skill_usee(%{usee_text: usee_text}, opts) do
    skill_usee(usee_text, opts)
  end
  def skill_usee(usee_text, opts) do
    usee_text
    |> String.replace("{user}", target_name(Keyword.get(opts, :user)))
  end

  @doc """
  Message for users of items

      iex> Game.Format.user_item(%{name: "Potion", user_text: "You used {name} on {target}."}, target: {:npc, %{name: "Bandit"}}, user: {:user, %{name: "Player"}})
      "You used {cyan}Potion{/cyan} on {yellow}Bandit{/yellow}."
  """
  def user_item(item, opts \\ []) do
    item.user_text
    |> String.replace("{name}", item_name(item))
    |> String.replace("{target}", target_name(Keyword.get(opts, :target)))
    |> String.replace("{user}", target_name(Keyword.get(opts, :user)))
  end

  @doc """
  Message for usees of items

      iex> Game.Format.usee_item(%{name: "Potion", usee_text: "You used {name} on {target}."}, target: {:npc, %{name: "Bandit"}}, user: {:user, %{name: "Player"}})
      "You used {cyan}Potion{/cyan} on {yellow}Bandit{/yellow}."
  """
  def usee_item(item, opts \\ []) do
    item.usee_text
    |> String.replace("{name}", item_name(item))
    |> String.replace("{target}", target_name(Keyword.get(opts, :target)))
    |> String.replace("{user}", target_name(Keyword.get(opts, :user)))
  end

  @doc """
  Format a target name, blue for user, yellow for npc

    iex> Game.Format.target_name({:user, %{name: "Player"}})
    "{blue}Player{/blue}"

    iex> Game.Format.target_name({:npc, %{name: "Bandit"}})
    "{yellow}Bandit{/yellow}"
  """
  @spec target_name({atom, map}) :: String.t
  def target_name({:npc, npc}), do: npc_name(npc)
  def target_name({:user, user}), do: player_name(user)

  def name(who), do: target_name(who)

  @doc """
  Colorize a user's name
  """
  @spec player_name(User.t()) :: String.t()
  def player_name(user), do: "{blue}#{user.name}{/blue}"

  @doc """
  Colorize an npc's name
  """
  @spec npc_name(NPC.t()) :: String.t()
  def npc_name(npc), do: "{yellow}#{npc.name}{/yellow}"

  @doc """
  Format an items name, cyan

    iex> Game.Format.item_name(%{name: "Potion"})
    "{cyan}Potion{/cyan}"
  """
  @spec item_name(Item.t()) :: String.t
  def item_name(item) do
    "{cyan}#{item.name}{/cyan}"
  end

  @doc """
  Format effects for display.
  """
  def effects([]), do: []
  def effects([effect | remaining]) do
    case effect do
      %{kind: "damage"} ->
        ["#{effect.amount} #{effect.type} damage is dealt." | effects(remaining)]
      %{kind: "damage/over-time"} ->
        ["#{effect.amount} #{effect.type} damage is dealt." | effects(remaining)]
      %{kind: "recover", type: "health"} ->
        ["#{effect.amount} damage is healed." | effects(remaining)]
      %{kind: "recover", type: "skill"} ->
        ["#{effect.amount} skill points are recovered." | effects(remaining)]
      %{kind: "recover", type: "move"} ->
        ["#{effect.amount} move points are recovered." | effects(remaining)]
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

  @doc """
  Format mail for a user

      iex> Game.Format.list_mail([%{id: 1, sender: %{name: "Player"}, title: "hello"}])
      "1 - {blue}Player{/blue} - hello"
  """
  @spec list_mail([Mail.t()]) :: String.t()
  def list_mail(mail) do
    mail
    |> Enum.map(fn (mail) ->
      "#{mail.id} - #{player_name(mail.sender)} - #{mail.title}"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Format a single piece of mail for a user

      iex> Game.Format.display_mail(%{id: 1,sender: %{name: "Player"}, title: "hello", body: "A\\nlong message"})
      "1 - {blue}Player{/blue} - hello\\n----------------------\\n\\nA\\nlong message"
  """
  @spec display_mail(Mail.t()) :: String.t()
  def display_mail(mail) do
    title = "#{mail.id} - #{player_name(mail.sender)} - #{mail.title}"
    "#{title}\n#{underline(title)}\n\n#{mail.body}"
  end
end
