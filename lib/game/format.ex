defmodule Game.Format do
  @moduledoc """
  Format data into strings to send to the connected player
  """

  import Game.Format.Context

  alias Data.Mail
  alias Data.Save
  alias Data.Skill
  alias Game.Color
  alias Game.Format.Channels
  alias Game.Format.Items
  alias Game.Format.Listen
  alias Game.Format.Players
  alias Game.Format.Resources
  alias Game.Format.Table
  alias Game.Format.Template

  def currency(currency), do: Items.currency(currency)

  def channel_name(channel), do: Channels.channel_name(channel)

  def item_name(item), do: Items.item_name(item)

  def player_name(player), do: Players.player_name(player)

  @doc """
  Template a string

      iex> Game.Format.template(%{assigns: %{name: "Player"}}, "[name] says hello")
      "Player says hello"
  """
  def template(context, string) do
    Template.render(context, string)
  end

  @doc """
  Run through the resources parser
  """
  def resources(string) do
    Resources.parse(string)
  end

  @doc """
  Display a zone's name
  """
  def zone_name(zone) do
    "{zone}#{zone.name}{/zone}"
  end

  @doc """
  Create an 'underline'

  Example:

      iex> Game.Format.underline("Room Name")
      "-------------"

      iex> Game.Format.underline("{player}Player{/player}")
      "----------"
  """
  def underline(nil), do: ""

  def underline(string) do
    1..(String.length(Color.strip_color(string)) + 4)
    |> Enum.map(fn _ -> "-" end)
    |> Enum.join("")
  end

  @doc """
  Wraps lines of text
  """
  @spec wrap(String.t()) :: String.t()
  def wrap(string) do
    string
    |> String.replace("\n", "{newline}")
    |> String.replace("\r", "")
    |> String.split(~r/( |{[^}]*})/, include_captures: true)
    |> _wrap("", "")
  end

  @doc """
  Wraps a list of text
  """
  @spec wrap_lines([String.t()]) :: String.t()
  def wrap_lines(lines) do
    lines
    |> Enum.join(" ")
    |> wrap()
  end

  defp _wrap([], line, string), do: join(string, line, "\n")

  defp _wrap(["{newline}" | left], line, string) do
    case string do
      "" ->
        _wrap(left, "", line)

      _ ->
        _wrap(left, "", Enum.join([string, line], "\n"))
    end
  end

  defp _wrap([word | left], line, string) do
    test_line = "#{line} #{word}" |> Color.strip_color() |> String.trim()

    case String.length(test_line) do
      len when len < 80 ->
        _wrap(left, join(line, word, ""), string)

      _ ->
        _wrap(left, word, join(string, String.trim(line), "\n"))
    end
  end

  defp join(str1, str2, joiner) do
    Enum.join([str1, str2] |> Enum.reject(&(&1 == "")), joiner)
  end

  @doc """
  The status of an NPC
  """
  def npc_status(npc) do
    context()
    |> assign(:name, npc_name_for_status(npc))
    |> template(npc.extra.status_line)
  end

  @doc """
  Look at an NPC
  """
  @spec npc_full(Npc.t()) :: String.t()
  def npc_full(npc) do
    context()
    |> assign(:name, npc_name(npc))
    |> assign(:status_line, npc_status(npc))
    |> template(resources(npc.extra.description))
  end

  @doc """
  Format items for sale in a shop
  """
  def list_shop(shop, items), do: Game.Format.Shops.list(shop, items)

  @doc """
  Format skills
  """
  @spec skills([Skill.t()]) :: String.t()
  def skills(skills)

  def skills(skills) do
    skills =
      skills
      |> Enum.map(&skill(&1))
      |> Enum.join("\n")

    """
    Known Skills
    #{underline("Known Skills")}

    #{skills}
    """
    |> String.trim()
  end

  @doc """
  Format a skill

      iex> skill = %{level: 1, name: "Slash", points: 2, command: "slash", description: "Fight your foe"}
      iex> Game.Format.skill(skill)
      "{skill}Slash{/skill} - Level 1 - 2sp\\nCommand: {command send='help slash'}slash{/command}\\nFight your foe\\n"
  """
  @spec skill(Skill.t()) :: String.t()
  def skill(skill) do
    """
    {skill}#{skill.name}{/skill} - Level #{skill.level} - #{skill.points}sp
    Command: {command send='help #{skill.command}'}#{skill.command}{/command}
    #{skill.description}
    """
  end

  @doc """
  Format a skill, from perspective of the player

      iex> Game.Format.skill_user(%{user_text: "Slash away"}, {:player, %{name: "Player"}}, {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> Game.Format.skill_user(%{user_text: "You slash away at [target]"}, {:player, %{name: "Player"}}, {:npc, %{name: "Bandit"}})
      "You slash away at {npc}Bandit{/npc}"
  """
  def skill_user(skill, player, target)

  def skill_user(%{user_text: user_text}, player, target) do
    context()
    |> assign(:user, target_name(player))
    |> assign(:target, target_name(target))
    |> template(user_text)
  end

  @doc """
  Format a skill, from the perspective of a usee

      iex> Game.Format.skill_usee(%{usee_text: "Slash away"}, user: {:npc, %{name: "Bandit"}}, target: {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> Game.Format.skill_usee(%{usee_text: "You were slashed at by [user]"}, user: {:npc, %{name: "Bandit"}}, target: {:player, %{name: "Player"}})
      "You were slashed at by {npc}Bandit{/npc}"
  """
  def skill_usee(skill, opts \\ [])

  def skill_usee(%{usee_text: usee_text}, opts) do
    skill_usee(usee_text, opts)
  end

  def skill_usee(usee_text, opts) do
    context()
    |> assign(:user, target_name(Keyword.get(opts, :user)))
    |> assign(:target, target_name(Keyword.get(opts, :target)))
    |> template(usee_text)
  end

  @doc """
  Format a target name, blue for player, yellow for npc

    iex> Game.Format.target_name({:player, %{name: "Player"}})
    "{player}Player{/player}"

    iex> Game.Format.target_name({:npc, %{name: "Bandit"}})
    "{npc}Bandit{/npc}"
  """
  @spec target_name(Character.t()) :: String.t()
  def target_name({:npc, npc}), do: npc_name(npc)
  def target_name({:player, player}), do: player_name(player)

  def name(who), do: target_name(who)

  @doc """
  Colorize an npc's name
  """
  @spec npc_name(NPC.t()) :: String.t()
  def npc_name(npc), do: "{npc}#{npc.name}{/npc}"

  def npc_name_for_status(npc) do
    case Map.get(npc.extra, :is_quest_giver, false) do
      true -> "#{npc_name(npc)} ({quest}!{/quest})"
      false -> npc_name(npc)
    end
  end

  @doc """
  Format a skill name, white

    iex> Game.Format.skill_name(%{name: "Slash"})
    "{skill}Slash{/skill}"
  """
  @spec skill_name(Skill.t()) :: String.t()
  def skill_name(skill) do
    "{skill}#{skill.name}{/skill}"
  end

  @doc """
  Format a shop name, magenta

     iex> Game.Format.shop_name(%{name: "Shop"})
     "{shop}Shop{/shop}"
  """
  def shop_name(shop) do
    "{shop}#{shop.name}{/shop}"
  end

  @doc """
  Format effects for display.
  """
  def effects([], _target), do: []

  def effects([effect | remaining], target) do
    case effect do
      %{kind: "damage"} ->
        [
          "#{effect.amount} #{effect.type} damage is dealt to #{name(target)}."
          | effects(remaining, target)
        ]

      %{kind: "damage/over-time"} ->
        [
          "#{effect.amount} #{effect.type} damage is dealt to #{name(target)}."
          | effects(remaining, target)
        ]

      %{kind: "recover", type: "health"} ->
        ["#{effect.amount} damage is healed to #{name(target)}." | effects(remaining, target)]

      %{kind: "recover", type: "skill"} ->
        ["#{effect.amount} skill points are recovered." | effects(remaining, target)]

      %{kind: "recover", type: "endurance"} ->
        ["#{effect.amount} endurance points are recovered." | effects(remaining, target)]

      _ ->
        effects(remaining, target)
    end
  end

  @doc """
  Format mail for a player
  """
  @spec list_mail([Mail.t()]) :: String.t()
  def list_mail(mail) do
    rows =
      mail
      |> Enum.map(fn mail ->
        [to_string(mail.id), player_name(mail.sender), mail.title]
      end)

    Table.format("You have #{length(mail)} unread mail.", rows, [5, 20, 30])
  end

  @doc """
  Format a single piece of mail for a player

      iex> Game.Format.display_mail(%{id: 1,sender: %{name: "Player"}, title: "hello", body: "A\\nlong message"})
      "1 - {player}Player{/player} - hello\\n----------------------\\n\\nA\\nlong message"
  """
  @spec display_mail(Mail.t()) :: String.t()
  def display_mail(mail) do
    title = "#{mail.id} - #{player_name(mail.sender)} - #{mail.title}"
    "#{title}\n#{underline(title)}\n\n#{mail.body}"
  end

  @doc """
  List out skills that a trainer will give
  """
  @spec trainable_skills(NPC.t(), [Skill.t()]) :: String.t()
  def trainable_skills(trainer, skills) do
    rows =
      skills
      |> Enum.map(fn {skill, cost} ->
        [to_string(skill.id), skill.name, skill.command, cost]
      end)

    rows = [["ID", "Name", "Command", "Cost"] | rows]

    Table.format("#{npc_name(trainer)} will train these skills:", rows, [5, 30, 20, 10])
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

  @doc """
  Format listen text for a room
  """
  def listen_room(room), do: Listen.to_room(room)
end
