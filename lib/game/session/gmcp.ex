defmodule Game.Session.GMCP do
  @moduledoc """
  Helpers for pushing GMCP data
  """

  alias Data.Exit
  alias Data.Room
  alias Game.Config
  alias Game.Format
  alias Game.Skills
  alias Game.Socket

  @doc """
  Handle a GMCP request from the client
  """
  def handle_gmcp(state, module, data)

  def handle_gmcp(state, "External.Discord.Hello", _data) do
    data = %{
      inviteurl: Config.discord_invite_url(),
      applicationid: Config.discord_client_id()
    }

    data =
      data
      |> Enum.reject(fn {_key, val} ->
        is_nil(val)
      end)
      |> Enum.into(%{})

    state |> Socket.push_gmcp("External.Discord.Info", data |> Poison.encode!())
  end

  def handle_gmcp(state, "External.Discord.Get", _data) do
    discord_status(state)
  end

  def handle_gmcp(state, "Character.Skills.Get", _data) do
    character_skills(state)
  end

  def handle_gmcp(state, "Target.Set", %{"name" => name}) do
    Game.Command.Target.run({:set, name}, state)
  end

  def handle_gmcp(state, "Target.Clear", _data) do
    Game.Command.Target.run({:clear}, state)
  end

  def handle_gmcp(_state, _module, _data), do: :ok

  @doc """
  Push Character data (save stats)
  """
  def character(state = %{character: character}) do
    data = %{
      name: character.name,
      level: character.save.level,
      class: %{
        name: character.class.name
      }
    }

    state |> Socket.push_gmcp("Character.Info", data |> Poison.encode!())
  end

  @doc """
  Push Character.Vitals data (save stats)
  """
  def vitals(state = %{save: save}) do
    vitals =
      save.stats
      |> Map.put(:experience_towards_level, rem(save.experience_points, 1000))

    state |> Socket.push_gmcp("Character.Vitals", vitals |> Poison.encode!())
  end

  @doc """
  Push Room.Info data
  """
  def room(state, room, items) do
    state |> Socket.push_gmcp("Room.Info", room |> room_info(items) |> Poison.encode!())
  end

  @doc """
  A character enters a room

  Does not push directly to the socket
  """
  def character_enter(state, character) do
    state
    |> Socket.push_gmcp(
      "Room.Character.Enter",
      character |> character_info() |> Poison.encode!()
    )
  end

  @doc """
  A character leaves a room

  Does not push directly to the socket
  """
  def character_leave(state, character) do
    state
    |> Socket.push_gmcp(
      "Room.Character.Leave",
      character |> character_info() |> Poison.encode!()
    )
  end

  @doc """
  Send the player's target info
  """
  def target(state, character) do
    state
    |> Socket.push_gmcp("Target.Character", character |> character_info() |> Poison.encode!())
  end

  @doc """
  A character targeted the player
  """
  def counter_targeted(state, character) do
    state |> Socket.push_gmcp("Target.You", character |> character_info() |> Poison.encode!())
  end

  @doc """
  Send a target cleared message
  """
  def clear_target(state) do
    state |> Socket.push_gmcp("Target.Clear", "{}")
  end

  @doc """
  Send a map message
  """
  def map(state, map) do
    state |> Socket.push_gmcp("Zone.Map", %{map: map} |> Poison.encode!())
  end

  @doc """
  Push a new channel message
  """
  def channel_broadcast(state, channel, message) do
    data = %{
      channel: channel,
      from: character_info({message.type, message.sender}),
      message: message.message,
      formatted: message.formatted
    }

    state |> Socket.push_gmcp("Channels.Broadcast", Poison.encode!(data))
  end

  @doc """
  Push a new tell
  """
  def tell(state, character, message) do
    data = %{
      from: character_info(character),
      message: message.message
    }

    state |> Socket.push_gmcp("Channels.Tell", Poison.encode!(data))
  end

  @doc """
  Push a new room heard
  """
  def room_heard(state, message) do
    data = %{
      from: character_info({message.type, message.sender}),
      message: message.message
    }

    state |> Socket.push_gmcp("Room.Heard", Poison.encode!(data))
  end

  @doc """
  Push a new room whisper
  """
  def room_whisper(state, message) do
    data = %{
      from: character_info({message.type, message.sender}),
      message: message.message
    }

    state |> Socket.push_gmcp("Room.Whisper", Poison.encode!(data))
  end

  @doc """
  Push a new mail
  """
  def mail_new(state, mail) do
    data = %{
      id: mail.id,
      from: player_info(mail.sender),
      title: mail.title
    }

    state |> Socket.push_gmcp("Mail.New", Poison.encode!(data))
  end

  @doc """
  Push player configuration to the client
  """
  def config(state, config) do
    state |> Socket.push_gmcp("Config.Update", Poison.encode!(config))
  end

  @doc """
  Send the player's configured action bar
  """
  def config_actions(state) do
    actions =
      state.character.save.actions
      |> Enum.map(&Map.delete(&1, :__struct__))
      |> Enum.map(&config_action_transform/1)

    data = %{actions: actions}

    state |> Socket.push_gmcp("Config.Actions", Poison.encode!(data))
  end

  def config_action_transform(action = %{type: "skill"}) do
    case Skills.skill(action.id) do
      nil ->
        nil

      skill ->
        action
        |> Map.delete(:id)
        |> Map.put(:key, skill.api_id)
    end
  end

  def config_action_transform(action), do: action

  @doc """
  Push Core.Heartbeat
  """
  def heartbeat(state) do
    state |> Socket.push_gmcp("Core.Heartbeat", Poison.encode!(%{}))
  end

  @doc """
  Let the player know the skill is inactive
  """
  def skill_state(state, skill, opts) do
    data = %{
      key: skill.api_id,
      name: skill.name,
      command: skill.command,
      active: opts[:active]
    }

    state |> Socket.push_gmcp("Character.Skill", Poison.encode!(data))
  end

  @doc """
  Send the player's skills
  """
  def character_skills(state) do
    skills =
      state.character.save.skill_ids
      |> Skills.skills()
      |> Enum.map(fn skill ->
        %{
          key: skill.api_id,
          name: skill.name,
          command: skill.command,
          points: skill.points,
          cooldown: skill.cooldown_time
        }
      end)

    data = %{skills: skills}

    state |> Socket.push_gmcp("Character.Skills", Poison.encode!(data))
  end

  @doc """
  Send discord status
  """
  def discord_status(state) do
    data = %{
      game: Config.game_name(),
      starttime: state.session_started_at |> Timex.to_unix()
    }

    state |> Socket.push_gmcp("External.Discord.Status", data |> Poison.encode!())
  end

  defp room_info(room, items) do
    room
    |> Map.take([:id, :name, :ecology, :x, :y, :map_layer])
    |> Map.merge(%{
      zone: zone_info(room),
      description: VML.collapse(Format.Rooms.room_description(room)),
      items: render_many(items),
      players: render_many(room, :players),
      npcs: render_many(room, :npcs),
      shops: render_many(room, :shops),
      exits: render_many(room, :exits)
    })
  end

  @doc """
  Get info for an NPC or a User
  """
  def character_info({:player, player}), do: player_info(player)
  def character_info({:npc, npc}), do: npc_info(npc)
  def character_info({:gossip, player_name}), do: gossip_info(player_name)

  @doc """
  Gather information for a player
  """
  def player_info(player) do
    %{
      type: :player,
      id: Map.get(player, :id, nil),
      name: player.name
    }
  end

  @doc """
  Gather information for a npc
  """
  def npc_info(npc) do
    %{
      type: :npc,
      id: npc.id,
      name: npc.name
    }
  end

  @doc """
  Gather information for a Gossip player
  """
  def gossip_info(player_name) do
    %{
      type: :gossip,
      name: player_name
    }
  end

  @doc """
  Zone information
  """
  def zone_info(room) do
    %{
      id: room.zone.id,
      name: room.zone.name
    }
  end

  defp render_many(data) when is_list(data) do
    Enum.map(data, &%{id: &1.id, name: &1.name})
  end

  defp render_many(room, :exits) do
    room
    |> Room.exits()
    |> Enum.map(fn direction ->
      room_exit = Exit.exit_to(room, direction)
      %{room_id: room_exit.finish_id, direction: direction}
    end)
  end

  defp render_many(room, :npcs) do
    Enum.map(room.npcs, fn npc ->
      %{id: npc.id, name: npc.name, status_line: Format.NPCs.npc_status(npc)}
    end)
  end

  defp render_many(room, :players) do
    Enum.map(room.players, fn player ->
      %{id: player.id, name: player.name, status_line: Format.Players.player_full(player)}
    end)
  end

  defp render_many(struct, key) do
    case struct do
      %{^key => data} when data != nil ->
        render_many(data)

      _ ->
        []
    end
  end
end
