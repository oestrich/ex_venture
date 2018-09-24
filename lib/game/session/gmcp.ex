defmodule Game.Session.GMCP do
  @moduledoc """
  Helpers for pushing GMCP data
  """

  use Networking.Socket

  alias Data.Exit
  alias Data.Room
  alias Game.Config
  alias Game.Skills

  @doc """
  Handle a GMCP request from the client
  """
  def handle_gmcp(state, module, data)

  def handle_gmcp(state, "External.Discord.Hello", _data) do
    data = %{
      inviteurl: Config.discord_invite_url(),
      applicationid: Config.discord_client_id(),
    }

    data =
      data
      |> Enum.reject(fn {_key, val} ->
        is_nil(val)
      end)
      |> Enum.into(%{})

    state.socket |> @socket.push_gmcp("External.Discord.Info", data |> Poison.encode!())
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

  def handle_gmcp(state, _module, _data), do: state

  @doc """
  Push Character data (save stats)
  """
  @spec character(map) :: :ok
  def character(%{socket: socket, user: player}) do
    data = %{
      name: player.name,
      level: player.save.level,
      class: %{
        name: player.class.name
      }
    }

    socket |> @socket.push_gmcp("Character.Info", data |> Poison.encode!())
  end

  @doc """
  Push Character.Vitals data (save stats)
  """
  @spec vitals(map) :: :ok
  def vitals(%{socket: socket, save: save}) do
    vitals =
      save.stats
      |> Map.put(:experience_towards_level, rem(save.experience_points, 1000))

    socket |> @socket.push_gmcp("Character.Vitals", vitals |> Poison.encode!())
  end

  @doc """
  Push Room.Info data
  """
  @spec room(map, Room.t(), [Item.t()]) :: :ok
  def room(%{socket: socket}, room, items) do
    socket |> @socket.push_gmcp("Room.Info", room |> room_info(items) |> Poison.encode!())
  end

  @doc """
  A character enters a room

  Does not push directly to the socket
  """
  @spec character_enter(map, Character.t()) :: {String.t(), map}
  def character_enter(%{socket: socket}, character) do
    socket
    |> @socket.push_gmcp(
      "Room.Character.Enter",
      character |> character_info() |> Poison.encode!()
    )
  end

  @doc """
  A character leaves a room

  Does not push directly to the socket
  """
  @spec character_leave(map, Character.t()) :: {String.t(), map}
  def character_leave(%{socket: socket}, character) do
    socket
    |> @socket.push_gmcp(
      "Room.Character.Leave",
      character |> character_info() |> Poison.encode!()
    )
  end

  @doc """
  Send the player's target info
  """
  @spec target(map, Character.t()) :: :ok
  def target(%{socket: socket}, character) do
    socket
    |> @socket.push_gmcp("Target.Character", character |> character_info() |> Poison.encode!())
  end

  @doc """
  A character targeted the player
  """
  @spec counter_targeted(map, Character.t()) :: :ok
  def counter_targeted(%{socket: socket}, character) do
    socket |> @socket.push_gmcp("Target.You", character |> character_info() |> Poison.encode!())
  end

  @doc """
  Send a target cleared message
  """
  @spec clear_target(map) :: :ok
  def clear_target(%{socket: socket}) do
    socket |> @socket.push_gmcp("Target.Clear", "{}")
  end

  @doc """
  Send a map message
  """
  @spec map(map, String.t()) :: :ok
  def map(%{socket: socket}, map) do
    socket |> @socket.push_gmcp("Zone.Map", %{map: map} |> Poison.encode!())
  end

  @doc """
  Push a new channel message
  """
  @spec channel_broadcast(State.t(), String.t(), Message.t()) :: :ok
  def channel_broadcast(%{socket: socket}, channel, message) do
    data = %{
      channel: channel,
      from: character_info({message.type, message.sender}),
      message: message.message,
      formatted: message.formatted,
    }

    socket |> @socket.push_gmcp("Channels.Broadcast", Poison.encode!(data))
  end

  @doc """
  Push a new tell
  """
  @spec tell(State.t(), Character.t(), Message.t()) :: :ok
  def tell(%{socket: socket}, character, message) do
    data = %{
      from: character_info(character),
      message: message.message
    }

    socket |> @socket.push_gmcp("Channels.Tell", Poison.encode!(data))
  end

  @doc """
  Push a new room heard
  """
  @spec room_heard(State.t(), Message.t()) :: :ok
  def room_heard(%{socket: socket}, message) do
    data = %{
      from: character_info({message.type, message.sender}),
      message: message.message
    }

    socket |> @socket.push_gmcp("Room.Heard", Poison.encode!(data))
  end

  @doc """
  Push a new room whisper
  """
  @spec room_whisper(State.t(), Message.t()) :: :ok
  def room_whisper(%{socket: socket}, message) do
    data = %{
      from: character_info({message.type, message.sender}),
      message: message.message
    }

    socket |> @socket.push_gmcp("Room.Whisper", Poison.encode!(data))
  end

  @doc """
  Push a new mail
  """
  @spec mail_new(State.t(), Mail.t()) :: :ok
  def mail_new(%{socket: socket}, mail) do
    data = %{
      id: mail.id,
      from: player_info(mail.sender),
      title: mail.title
    }

    socket |> @socket.push_gmcp("Mail.New", Poison.encode!(data))
  end

  @doc """
  Push player configuration to the client
  """
  @spec config(State.t(), map()) :: :ok
  def config(%{socket: socket}, config) do
    socket |> @socket.push_gmcp("Config.Update", Poison.encode!(config))
  end

  @doc """
  Send the player's configured action bar
  """
  @spec config_actions(State.t()) :: :ok
  def config_actions(state) do
    actions =
      state.user.save.actions
      |> Enum.map(&Map.delete(&1, :__struct__))
      |> Enum.map(&config_action_transform/1)

    data = %{actions: actions}

    state.socket |> @socket.push_gmcp("Config.Actions", Poison.encode!(data))
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
  @spec heartbeat(map) :: :ok
  def heartbeat(%{socket: socket}) do
    socket |> @socket.push_gmcp("Core.Heartbeat", Poison.encode!(%{}))
  end

  @doc """
  Let the player know the skill is inactive
  """
  @spec skill_state(State.t(), Skill.t(), Keyword.t()) :: :ok
  def skill_state(%{socket: socket}, skill, opts) do
    data = %{
      key: skill.api_id,
      name: skill.name,
      command: skill.command,
      active: opts[:active]
    }

    socket |> @socket.push_gmcp("Character.Skill", Poison.encode!(data))
  end

  @doc """
  Send the player's skills
  """
  @spec character_skills(State.t()) :: :ok
  def character_skills(state) do
    skills =
      state.user.save.skill_ids
      |> Skills.skills()
      |> Enum.map(fn skill ->
        %{
          key: skill.api_id,
          name: skill.name,
          command: skill.command,
          points: skill.points,
          cooldown: skill.cooldown_time,
        }
      end)

    data = %{skills: skills}

    state.socket |> @socket.push_gmcp("Character.Skills", Poison.encode!(data))
  end

  @doc """
  Send discord status
  """
  @spec discord_status(State.t()) :: :ok
  def discord_status(state) do
    data = %{
      game: Config.game_name(),
      starttime: state.session_started_at |> Timex.to_unix()
    }

    state.socket |> @socket.push_gmcp("External.Discord.Status", data |> Poison.encode!())
  end

  defp room_info(room, items) do
    room
    |> Map.take([:id, :name, :description, :ecology, :x, :y, :map_layer])
    |> Map.merge(%{
      zone: zone_info(room),
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
  @spec character_info(Character.t()) :: map()
  def character_info({:player, player}), do: player_info(player)
  def character_info({:npc, npc}), do: npc_info(npc)
  def character_info({:gossip, player_name}), do: gossip_info(player_name)

  @doc """
  Gather information for a player
  """
  @spec player_info(User.t()) :: map
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
  @spec npc_info(NPC.t()) :: map
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
  @spec gossip_info(String.t()) :: map()
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

  defp render_many(struct, key) do
    case struct do
      %{^key => data} when data != nil ->
        render_many(data)

      _ ->
        []
    end
  end
end
