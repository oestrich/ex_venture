defmodule Game.Command.Quest do
  @moduledoc """
  The "quest" command, reaches straight to the database for most actions
  """

  use Game.Command
  use Game.Currency
  use Game.NPC

  alias Game.Player
  alias Game.Quest
  alias Game.Session.Character

  commands([{"quest", ["quests"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Quest"
  def help(:short), do: "View information about your current quests"

  def help(:full) do
    """
    #{help(:short)}. Quests are handed out by NPCs that
    have a "({yellow}!{/yellow})" next to their name. You must {command}greet{/command} NPCs in order for them to give
    you a quest. See more at {command}help greet{/command}.

    Viewing all active quests:

    [ ] > {command}quest{/command}

    View the requirements for a quest:

    [ ] > {command}quest show 1{/command}
    [ ] > {command}quest info 1{/command}

    Quests are tracked as you pick them up. One quest will be the tracked quest
    at a time. This quest is viewable with a shortened command.

    [ ] > {command}quest info{/command}

    You can track new quests with the track sub-command. This will replace your
    currently tracked quest.

    [ ] > {command}quest track 1{/command}

    Completing quests:

    You can complete a quest after all the quest requirements are fulfilled. Go back
    to the quest giver and use the {command}quest complete{/command} command.

    [ ] > {command}quest complete{/command}
    [ ] > {command}quest complete 1{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Quest.parse("quest")
      {:list, :active}
      iex> Game.Command.Quest.parse("quests")
      {:list, :active}

      iex> Game.Command.Quest.parse("quest show 10")
      {:show, "10"}
      iex> Game.Command.Quest.parse("quest info 10")
      {:show, "10"}

      iex> Game.Command.Quest.parse("quest info")
      {:show, :tracked}

      iex> Game.Command.Quest.parse("quest track 10")
      {:track, "10"}

      iex> Game.Command.Quest.parse("quest complete 10")
      {:complete, "10"}
      iex> Game.Command.Quest.parse("quest complete")
      {:complete, :any}

      iex> Game.Command.Channels.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("quest"), do: {:list, :active}
  def parse("quests"), do: {:list, :active}
  def parse("quest show " <> quest_id), do: {:show, quest_id}
  def parse("quest info " <> quest_id), do: {:show, quest_id}
  def parse("quest info"), do: {:show, :tracked}
  def parse("quest track " <> quest_id), do: {:track, quest_id}
  def parse("quest complete"), do: {:complete, :any}
  def parse("quest complete " <> quest_id), do: {:complete, quest_id}

  @impl Game.Command
  def run(command, state)

  def run({:list, :active}, %{socket: socket, user: user}) do
    case Quest.for(user) do
      [] ->
        socket |> @socket.echo(gettext("You have no active quests."))

      quests ->
        socket |> @socket.echo(Format.quest_progress(quests))
    end

    :ok
  end

  def run({:show, :tracked}, %{socket: socket, user: user, save: save}) do
    case Quest.current_tracked_quest(user) do
      nil ->
        socket |> @socket.echo(gettext("You do not have have a tracked quest."))

      progress ->
        socket |> @socket.echo(Format.quest_detail(progress, save))
    end

    :ok
  end

  def run({:show, quest_id}, %{socket: socket, user: user, save: save}) do
    case Quest.progress_for(user, quest_id) do
      {:ok, progress} ->
        socket |> @socket.echo(Format.quest_detail(progress, save))

      {:error, :not_found} ->
        socket |> @socket.echo(gettext("You have not started this quest."))

      {:error, :invalid_id} ->
        socket |> @socket.echo(gettext("Could not parse the quest ID, please try again."))
    end
  end

  # find quests that are completed and see if npc in the room
  def run({:complete, :any}, state = %{socket: socket, user: user, save: save}) do
    {:ok, room} = @environment.look(save.room_id)
    npc_ids = Enum.map(room.npcs, & &1.extra.original_id)

    user
    |> Quest.for()
    |> find_active_quests_for_room(npc_ids, socket)
    |> filter_for_ready_to_complete(save)
    |> maybe_complete(state)
  end

  def run({:complete, quest_id}, state = %{socket: socket, user: user}) do
    case Quest.progress_for(user, quest_id) do
      {:ok, progress} ->
        progress
        |> gate_for_active(state)
        |> check_npc_is_in_room(state)
        |> check_steps_are_complete(state)
        |> complete_quest(state)

      {:error, :not_found} ->
        socket |> @socket.echo(gettext("You have not started this quest."))

      {:error, :invalid_id} ->
        socket |> @socket.echo(gettext("Could not parse the quest ID, please try again."))
    end
  end

  def run({:track, quest_id}, %{socket: socket, user: user}) do
    case Quest.track_quest(user, quest_id) do
      {:error, :not_started} ->
        socket |> @socket.echo(gettext("You have not started this quest to start tracking it."))

      {:ok, progress} ->
        message = gettext("You are tracking %{name}.", name: Format.quest_name(progress.quest))
        socket |> @socket.echo(message)
    end
  end

  @doc """
  Check if the quest is in the active state
  """
  @spec gate_for_active(QuestProgress.t(), State.t()) :: :ok | QuestProgress.t()
  def gate_for_active(progress, state) do
    case progress.status do
      "active" ->
        progress

      _ ->
        state.socket |> @socket.echo(gettext("This quest is already complete."))
    end
  end

  @doc """
  Check if the quest giver is in the same room
  """
  @spec check_npc_is_in_room(QuestProgress.t(), State.t()) :: :ok | QuestProgress.t()
  def check_npc_is_in_room(:ok, _state), do: :ok

  def check_npc_is_in_room(progress, %{socket: socket, save: save}) do
    {:ok, room} = @environment.look(save.room_id)

    npc =
      room
      |> Map.get(:npcs)
      |> Enum.find(fn npc ->
        npc.extra.original_id == progress.quest.giver_id
      end)

    case npc do
      nil ->
        message = gettext("The quest giver %{name} cannot be found.", name: Format.npc_name(progress.quest.giver))
        socket |> @socket.echo(message)

      _ ->
        {progress, npc}
    end
  end

  @doc """
  Verify the quest is complete
  """
  @spec check_steps_are_complete({QuestProgress.t(), NPC.t()}, State.t()) ::
          :ok | QuestProgress.t()
  def check_steps_are_complete(:ok, _state), do: :ok

  def check_steps_are_complete({progress, npc}, state) do
    case Quest.requirements_complete?(progress, state.save) do
      true ->
        {progress, npc}

      false ->
        response =
          Format.wrap_lines([
            gettext("You have not completed the requirements for the quest."),
            gettext("See {command}quest info %{id}{/command} for your current progress.)", id: progress.quest_id)
          ])

        state.socket |> @socket.echo(response)
    end
  end

  @spec complete_quest({QuestProgress.t(), NPC.t()}, State.t()) :: QuestProgress.t()
  def complete_quest(:ok, _state), do: :ok

  def complete_quest({progress, npc}, state = %{socket: socket, user: user, save: save}) do
    %{quest: quest} = progress

    case Quest.complete(progress, save) do
      {:ok, save} ->
        socket |> @socket.echo("Quest completed!\n\nYou gain #{quest.currency} #{currency()}.")

        save = %{save | currency: save.currency + quest.currency}
        state = Player.update_save(state, save)

        state = Character.apply_experience(state, {:quest, quest})

        npc.id |> @npc.notify({"quest/completed", user, quest})

        {:update, state}

      _ ->
        message = 
          gettext("Something went wrong, please contact the administrators if you encounter a problem again.")

        socket |> @socket.echo(message)
    end
  end

  defp find_active_quests_for_room([], _npc_ids, socket) do
    socket |> @socket.echo(gettext("You have no quests to complete"))
  end

  defp find_active_quests_for_room(quest_progress, npc_ids, _) do
    Enum.filter(quest_progress, fn progress ->
      progress.quest.giver_id in npc_ids
    end)
  end

  defp filter_for_ready_to_complete(:ok, _), do: :ok

  defp filter_for_ready_to_complete(quest_progress, save) do
    Enum.find(quest_progress, fn progress ->
      Quest.requirements_complete?(progress, save)
    end)
  end

  defp maybe_complete(:ok, _), do: :ok

  defp maybe_complete(nil, %{socket: socket}) do
    message =
      gettext("You cannot complete a quest in this room. Find the quest giver or complete required steps.")

    socket |> @socket.echo(message)
  end

  defp maybe_complete(progress, state), do: run({:complete, progress.quest_id}, state)
end
