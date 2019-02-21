defmodule Game.Session.Character do
  @moduledoc """
  Implementation for character callbacks
  """

  alias Game.Account
  alias Game.Character
  alias Game.Events.CharacterDied
  alias Game.Events.CurrencyDropped
  alias Game.Events.CurrencyReceived
  alias Game.Events.ItemDropped
  alias Game.Events.ItemReceived
  alias Game.Events.MailReceived
  alias Game.Events.PlayerSignedIn
  alias Game.Events.PlayerSignedOut
  alias Game.Events.RoomEntered
  alias Game.Events.RoomHeard
  alias Game.Events.RoomLeft
  alias Game.Events.RoomOverheard
  alias Game.Events.RoomWhispered
  alias Game.Experience
  alias Game.Format
  alias Game.Format.Effects, as: FormatEffects
  alias Game.Hint
  alias Game.Items
  alias Game.Player
  alias Game.Quest
  alias Game.Session
  alias Game.Session.Effects
  alias Game.Session.GMCP
  alias Game.Session.Regen
  alias Game.Socket

  @doc """
  Callback for being targeted
  """
  def targeted(state, character) do
    state |> Socket.echo("You are being targeted by #{Format.name(character)}.")
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
    case Character.who(target) == {:player, state.character.id} do
      true ->
        state

      false ->
        message = Enum.join(FormatEffects.effects(effects, target), "\n")
        state |> Socket.echo(message)
        state |> Session.Process.prompt()
        state
    end
  end

  @doc """
  Callback for being notified of events
  """
  def notify(state, event)

  def notify(state, %CharacterDied{character: character, killer: who}) do
    state |> Socket.echo("#{Format.name(character)} has died.")
    state |> GMCP.character_leave(character)

    # see if who is you
    case Character.who(who) == Character.who({:player, state.character}) do
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

  def notify(state, %CurrencyDropped{character: character, amount: amount}) do
    case Character.who(character) == {:player, state.character.id} do
      true ->
        state

      false ->
        message = "#{Format.name(character)} dropped #{Format.currency(amount)}."
        Socket.echo(state, message)

        state
    end
  end

  def notify(state, %CurrencyReceived{character: character, amount: amount}) do
    message = "You received #{Format.currency(amount)} from #{Format.name(character)}."
    Socket.echo(state, message)

    save = %{state.save | currency: state.save.currency + amount}
    Player.update_save(state, save)
  end

  def notify(state, %ItemDropped{character: character, instance: item}) do
    case Character.who(character) == {:player, state.character.id} do
      true ->
        state

      false ->
        message = "#{Format.name(character)} dropped #{Format.item_name(item)}."
        Socket.echo(state, message)

        state
    end
  end

  def notify(state = %{save: save}, %ItemReceived{character: character, instance: instance}) do
    item = Items.item(instance)

    state
    |> Socket.echo("You received #{Format.item_name(item)} from #{Format.name(character)}.")

    save = %{save | items: [instance | save.items]}
    Player.update_save(state, save)
  end

  def notify(state, %MailReceived{mail: mail}) do
    state
    |> Socket.echo("You have new mail. {command}mail read #{mail.id}{/command} to read it.")

    state |> GMCP.mail_new(mail)
    state
  end

  def notify(state, %PlayerSignedOut{character: character}) do
    state |> Socket.echo("#{Format.name(character)} went offline.")
    state
  end

  def notify(state, %PlayerSignedIn{character: character}) do
    state |> Socket.echo("#{Format.name(character)} is now online.")
    state
  end

  def notify(state, %RoomEntered{character: character, reason: reason}) do
    case reason do
      {:enter, direction} ->
        state
        |> Socket.echo(
          "#{Format.name(character)} enters from the {command}#{direction}{/command}."
        )

      :teleport ->
        state |> Socket.echo("#{Format.name(character)} warps in.")

      :login ->
        state |> Socket.echo("#{Format.name(character)} logs in.")

      :respawn ->
        state |> Socket.echo("#{Format.name(character)} respawns.")
    end

    state |> GMCP.character_enter(character)
    state
  end

  def notify(state, %RoomLeft{character: character, reason: reason}) do
    case reason do
      {:leave, direction} ->
        state
        |> Socket.echo(
          "#{Format.name(character)} leaves heading {command}#{direction}{/command}."
        )

      :signout ->
        state |> Socket.echo("#{Format.name(character)} signs out.")

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

  def notify(state, %RoomHeard{message: message}) do
    state |> GMCP.room_heard(message)
    state |> Socket.echo(message.formatted)
    state
  end

  def notify(state, %RoomOverheard{characters: characters, message: message}) do
    skip_echo? =
      Enum.any?(characters, fn character ->
        Character.who(character) == Character.who({:player, state.character})
      end)

    case skip_echo? do
      true ->
        state

      false ->
        state |> Socket.echo(message)
        state
    end
  end

  def notify(state, %RoomWhispered{message: message}) do
    state |> GMCP.room_whisper(message)
    state |> Socket.echo(message.formatted)
    state
  end

  def notify(state, {"quest/new", quest}) do
    state
    |> Socket.echo("You received a new quest, #{Format.Quests.quest_name(quest)} (#{quest.id}).")

    Hint.gate(state, "quests.new", id: quest.id)

    Quest.track_quest(state.character, quest.id)

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
    state |> Socket.echo("You are now targeting #{Format.name(player)}.")

    state |> GMCP.target(player)

    player = Character.who(player)
    Character.being_targeted(player, {:player, state.character})

    %{state | target: player}
  end

  @doc """
  Get a possible new target from the list
  """
  @spec possible_new_target(map()) :: Character.t()
  def possible_new_target(state) do
    state.is_targeting
    |> MapSet.to_list()
    |> Enum.reject(&(&1 == {:player, state.character.id}))
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
          state |> Socket.echo("You received #{experience} experience points.")
          state |> GMCP.vitals()

          state

        {:ok, :level_up, experience, state} ->
          state |> Socket.echo("You received #{experience} experience points.")
          state |> Socket.echo("You leveled up!")

          # May add to the action bar
          state =
            state
            |> Experience.notify_new_skills()
            |> unlock_class_proficiencies()

          state |> GMCP.vitals()
          state |> GMCP.character_skills()
          state |> GMCP.config_actions()

          state
      end

    state |> GMCP.character()
    state
  end

  defp unlock_class_proficiencies(state) do
    character = Account.unlock_class_proficiencies(state.character)
    Player.update_save(state, character.save)
  end

  @doc """
  Track quest progress if an npc was killed
  """
  def track_quest_progress(state, {:player, _player}), do: state

  def track_quest_progress(state, {:npc, npc}) do
    Quest.track_progress(state.character, {:npc, %{npc | id: npc.original_id}})
    state
  end
end
