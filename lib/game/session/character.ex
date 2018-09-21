defmodule Game.Session.Character do
  @moduledoc """
  Implementation for character callbacks
  """

  use Networking.Socket

  alias Game.Character
  alias Game.Experience
  alias Game.Format
  alias Game.Hint
  alias Game.Items
  alias Game.Quest
  alias Game.Session
  alias Game.Session.Effects
  alias Game.Session.GMCP
  alias Game.Session.Regen

  @doc """
  Callback for being targeted
  """
  def targeted(state = %{socket: socket}, character) do
    socket |> @socket.echo("You are being targeted by #{Format.name(character)}.")
    state |> GMCP.counter_targeted(character)

    state
    |> maybe_target(character)
    |> Map.put(:is_targeting, MapSet.put(state.is_targeting, Character.who(character)))
  end

  @doc """
  Callback for applying effects
  """
  def apply_effects(state, effects, from, description) do
    state = Effects.apply(effects, from, description, state)
    state = Regen.maybe_trigger_regen(state)
    state |> Session.Process.prompt()
    state
  end

  @doc """
  Callback for after a player sent effects to another character
  """
  def effects_applied(state, effects, target) do
    case Character.who(target) == {:player, state.user.id} do
      true ->
        state

      false ->
        message = Enum.join(Format.effects(effects, target), "\n")
        state.socket |> @socket.echo(message)
        state |> Session.Process.prompt()
        state
    end
  end

  @doc """
  Callback for being notified of events
  """
  def notify(state, event)

  def notify(state, {"character/died", character, :character, who}) do
    state.socket |> @socket.echo("#{Format.name(character)} has died.")
    state |> GMCP.character_leave(character)

    # see if who is you
    case Character.who(who) == Character.who({:player, state.user}) do
      true ->
        state =
          state
          |> apply_experience(character)
          |> track_quest_progress(character)

        case Character.who(character) == Character.who(state.target) do
          true ->
            state
            |> Map.put(:target, nil)
            |> remove_from_targeting_list(character)
            |> maybe_target()

          false ->
            state
        end

      false ->
        state
    end
  end

  def notify(state, {"currency/dropped", character, currency}) do
    case Character.who(character) == {:player, state.user.id} do
      true ->
        state

      false ->
        state.socket
        |> @socket.echo("#{Format.name(character)} dropped #{Format.currency(currency)}.")

        state
    end
  end

  def notify(state = %{save: save}, {"currency/receive", character, currency}) do
    state.socket
    |> @socket.echo("You received #{Format.currency(currency)} from #{Format.name(character)}.")

    save = %{save | currency: save.currency + currency}
    user = %{state.user | save: save}
    %{state | user: user, save: save}
  end

  def notify(state, {"item/dropped", character, item}) do
    case Character.who(character) == {:player, state.user.id} do
      true ->
        state

      false ->
        state.socket
        |> @socket.echo("#{Format.name(character)} dropped #{Format.item_name(item)}.")

        state
    end
  end

  def notify(state = %{save: save}, {"item/receive", character, instance}) do
    item = Items.item(instance)

    state.socket
    |> @socket.echo("You received #{Format.item_name(item)} from #{Format.name(character)}.")

    save = %{save | items: [instance | save.items]}
    user = %{state.user | save: save}
    %{state | user: user, save: save}
  end

  def notify(state, {"mail/new", mail}) do
    state.socket
    |> @socket.echo("You have new mail. {command}mail read #{mail.id}{/command} to read it.")

    state |> GMCP.mail_new(mail)
    state
  end

  def notify(state, {"player/offline", player}) do
    state.socket |> @socket.echo("#{Format.player_name(player)} went offline.")
    state
  end

  def notify(state, {"player/online", player}) do
    state.socket |> @socket.echo("#{Format.player_name(player)} is now online.")
    state
  end

  def notify(state, {"gossip/player-offline", game_name, player_name}) do
    name = "#{player_name}@#{game_name}"
    player = %{name: name}
    state.socket |> @socket.echo("#{Format.player_name(player)} went offline.")

    state
  end

  def notify(state, {"gossip/player-online", game_name, player_name}) do
    name = "#{player_name}@#{game_name}"
    player = %{name: name}
    state.socket |> @socket.echo("#{Format.player_name(player)} is now online.")

    state
  end

  def notify(state, {"room/entered", {character, reason}}) do
    case reason do
      {:enter, direction} ->
        state.socket
        |> @socket.echo(
          "#{Format.name(character)} enters from the {command}#{direction}{/command}."
        )

      :teleport ->
        state.socket |> @socket.echo("#{Format.name(character)} warps in.")

      :login ->
        state.socket |> @socket.echo("#{Format.name(character)} logs in.")

      :respawn ->
        state.socket |> @socket.echo("#{Format.name(character)} respawns.")
    end

    state |> GMCP.character_enter(character)
    state
  end

  def notify(state, {"room/leave", {character, reason}}) do
    case reason do
      {:leave, direction} ->
        state.socket
        |> @socket.echo(
          "#{Format.name(character)} leaves heading {command}#{direction}{/command}."
        )

      :signout ->
        state.socket |> @socket.echo("#{Format.name(character)} signs out.")

      :teleport ->
        :ok

      :death ->
        :ok
    end

    state |> GMCP.character_leave(character)

    target = Map.get(state, :target, nil)

    case Character.who(character) do
      ^target -> %{state | target: nil}
      _ -> state
    end
  end

  def notify(state, {"room/heard", message}) do
    state |> GMCP.room_heard(message)
    state.socket |> @socket.echo(message.formatted)
    state
  end

  def notify(state, {"room/overheard", characters, message}) do
    skip_echo? =
      Enum.any?(characters, fn character ->
        character == {:player, state.user}
      end)

    case skip_echo? do
      true ->
        state

      false ->
        state.socket |> @socket.echo(message)
        state
    end
  end

  def notify(state, {"room/whisper", message}) do
    state |> GMCP.room_whisper(message)
    state.socket |> @socket.echo(message.formatted)
    state
  end

  def notify(state, {"quest/new", quest}) do
    state.socket
    |> @socket.echo("You received a new quest, #{Format.quest_name(quest)} (#{quest.id}).")

    Hint.gate(state, "quests.new", id: quest.id)

    Quest.track_quest(state.user, quest.id)

    state
  end

  def notify(state, _), do: state

  @doc """
  Clean out the list as characters who were targeting you die
  """
  @spec remove_from_targeting_list(State.t(), Character.t()) :: State.t()
  def remove_from_targeting_list(state, target) do
    is_targeting =
      state.is_targeting
      |> MapSet.delete(Character.who(target))

    %{state | is_targeting: is_targeting}
  end

  @doc """
  Maybe target the character who targeted you, only if your own target is empty
  """
  @spec maybe_target(State.t()) :: State.t()
  def maybe_target(state = %{target: nil}) do
    case possible_new_target(state) do
      nil ->
        state

      player ->
        _target(state, player)
    end
  end

  def maybe_target(state), do: state

  @spec maybe_target(map, Character.t() | nil) :: map
  def maybe_target(state = %{target: nil}, player), do: _target(state, player)
  def maybe_target(state, _), do: state

  defp _target(state, player) do
    state.socket |> @socket.echo("You are now targeting #{Format.name(player)}.")

    state |> GMCP.target(player)

    player = Character.who(player)
    Character.being_targeted(player, {:player, state.user})

    %{state | target: player}
  end

  @doc """
  Get a possible new target from the list
  """
  @spec possible_new_target(map()) :: Character.t()
  def possible_new_target(state) do
    state.is_targeting
    |> MapSet.to_list()
    |> Enum.reject(&(&1 == {:player, state.user.id}))
    |> List.first()
    |> character_info()
  end

  @doc """
  Get a character's information, handles nil
  """
  def character_info(nil), do: nil
  def character_info(character), do: Character.info(character)

  @doc """
  Apply experience for killing an npc
  """
  def apply_experience(state, {:player, _player}), do: state

  def apply_experience(state, {:quest, quest}),
    do: gain_experience(state, quest.level, quest.experience)

  def apply_experience(state, {:npc, npc}),
    do: gain_experience(state, npc.level, npc.experience_points)

  defp gain_experience(state, level, experience_points) do
    state =
      case Experience.apply(state, level: level, experience_points: experience_points) do
        {:ok, experience, state} ->
          state.socket |> @socket.echo("You received #{experience} experience points.")
          state |> GMCP.vitals()

          state

        {:ok, :level_up, experience, state} ->
          state.socket |> @socket.echo("You received #{experience} experience points.")
          state.socket |> @socket.echo("You leveled up!")

          # May add to the action bar
          state = state |> Experience.notify_new_skills()

          state |> GMCP.vitals()
          state |> GMCP.character_skills()
          state |> GMCP.config_actions()

          state
      end

    state |> GMCP.character()
    state
  end

  @doc """
  Track quest progress if an npc was killed
  """
  def track_quest_progress(state, {:player, _player}), do: state

  def track_quest_progress(state, {:npc, npc}) do
    Quest.track_progress(state.user, {:npc, %{npc | id: npc.original_id}})
    state
  end
end
