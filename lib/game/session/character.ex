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
  def notify(state, event)

  def notify(state, {"character/died", character, :character, who}) do
    state.socket |> @socket.echo("#{Format.name(character)} has died")
    state |> GMCP.character_leave(character)

    # see if who is you
    case Character.who(who) == Character.who({:user, state.user}) do
      true ->
        state =
          state
          |> apply_experience(character)
          |> track_quest_progress(character)

        state |> Session.Process.prompt()

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

  def notify(state, {"mail/new", mail}) do
    state.socket |> @socket.echo("You have new mail. {white}mail read #{mail.id}{/white} to read it")
    state |> GMCP.mail_new(mail)
    state
  end

  def notify(state, {"room/entered", {character, reason}}) do
    case reason do
      :enter -> state.socket |> @socket.echo("#{Format.name(character)} enters")
      :respawn -> state.socket |> @socket.echo("#{Format.name(character)} respawns")
    end

    state |> GMCP.character_enter(character)
    state
  end

  def notify(state, {"room/leave", {character, reason}}) do
    case reason do
      :leave -> state.socket |> @socket.echo("#{Format.name(character)} leaves")
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
      nil -> state
      player -> _target(state, player)
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
    Character.being_targeted(player, {:user, state.user})

    %{state | target: player}
  end

  @doc """
  Get a possible new target from the list
  """
  @spec possible_new_target(map) :: Character.t()
  def possible_new_target(state) do
    state.is_targeting
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
