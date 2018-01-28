defmodule Game.Session.Character do
  @moduledoc """
  Implementation for character callbacks
  """

  use Networking.Socket

  alias Game.Character
  alias Game.Experience
  alias Game.Format
  alias Game.Quest
  alias Game.Session
  alias Game.Session.Effects
  alias Game.Session.GMCP

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
  Callback for someone stopping targeting you
  """
  def remove_target(state, character) do
    Session.echo(self(), "You are no longer being targeted by #{Format.name(character)}.")
    Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Character.who(character)))
  end

  @doc """
  Callback for applying effects
  """
  def apply_effects(state, effects, from, description) do
    state = Effects.apply(effects, from, description, state)
    state |> Session.Process.prompt()
    state
  end

  @doc """
  Callback for being notified of events
  """
  def notify(state, {"mail/new", mail}) do
    state.socket |> @socket.echo("You have new mail. {white}mail read #{mail.id}{/white} to read it")
    state |> GMCP.mail_new(mail)
    state
  end

  def notify(state, {"room/entered", {character, reason}}) do
    case reason do
      :enter -> Session.echo(self(), "#{Format.name(character)} enters")
      :respawn -> Session.echo(self(), "#{Format.name(character)} respawns")
    end

    state |> GMCP.character_enter(character)
    state
  end

  def notify(state, {"room/leave", {character, reason}}) do
    case reason do
      :leave -> Session.echo(self(), "#{Format.name(character)} leaves")
      :death -> :ok
    end

    state |> GMCP.character_leave(character)

    target = Map.get(state, :target, nil)

    case Character.who(character) do
      ^target -> %{state | target: nil}
      _ -> state
    end
  end

  def notify(state, {"room/heard", message}) do
    state.socket |> @socket.echo(message.formatted)
    state
  end

  def notify(state, {"quest/new", quest}) do
    Session.echo(
      self(),
      "You have a new quest available, #{Format.quest_name(quest)} (#{quest.id})"
    )

    state
  end

  def notify(state, _), do: state

  @doc """
  Callback for a target dying
  """
  def died(state = %{target: target}, who) when is_nil(target) do
    Session.echo(self(), "#{Format.target_name(who)} has died.")
    state
  end

  def died(state = %{socket: socket, user: user, target: target}, who) do
    socket |> @socket.echo("#{Format.target_name(who)} has died.")

    state =
      state
      |> apply_experience(who)
      |> track_quest_progress(who)

    state |> Session.Process.prompt()

    case Character.who(target) == Character.who(who) do
      true ->
        Character.remove_target(target, {:user, user})

        state
        |> Map.put(:target, nil)
        |> maybe_target(possible_new_target(state, target))

      false ->
        state
    end
  end

  @doc """
  Maybe target the character who targeted you, only if your own target is empty
  """
  @spec maybe_target(map, Character.t() | nil) :: map
  def maybe_target(state, player)
  def maybe_target(state, nil), do: state

  def maybe_target(state = %{socket: socket, target: nil, user: user}, player) do
    socket |> @socket.echo("You are now targeting #{Format.name(player)}.")
    state |> GMCP.target(player)
    player = Character.who(player)
    Character.being_targeted(player, {:user, user})
    Map.put(state, :target, player)
  end

  def maybe_target(state, _player), do: state

  @doc """
  Get a possible new target from the list
  """
  @spec possible_new_target(map, Character.t()) :: Character.t()
  def possible_new_target(state, target) do
    state.is_targeting
    |> MapSet.delete(Character.who(target))
    |> MapSet.to_list()
    |> List.first()
    |> character_info()
  end

  @doc """
  Get a character's information, handles nil
  """
  def character_info(nil), do: nil
  def character_info(player), do: Character.info(player)

  @doc """
  Apply experience for killing an npc
  """
  def apply_experience(state, {:user, _user}), do: state

  def apply_experience(state, {:npc, npc}) do
    Experience.apply(state, level: npc.level, experience_points: npc.experience_points)
  end

  @doc """
  Track quest progress if an npc was killed
  """
  def track_quest_progress(state, {:user, _user}), do: state

  def track_quest_progress(state, {:npc, npc}) do
    Quest.track_progress(state.user, {:npc, %{npc | id: npc.original_id}})
    state
  end
end
