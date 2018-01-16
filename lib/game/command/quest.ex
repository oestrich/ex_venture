defmodule Game.Command.Quest do
  @moduledoc """
  The "quest" command, reaches straight to the database for most actions
  """

  use Game.Command

  alias Game.Experience
  alias Game.Quest

  commands [{"quest", ["quests"]}], parse: false

  @impl Game.Command
  def help(:topic), do: "Quest"
  def help(:short), do: "View information about your current quests"
  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {white}quest{/white}

    Example:
    [ ] > {white}quest show 1{/white}
    [ ] > {white}quest info 1{/white}
    """
  end

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

      iex> Game.Command.Quest.parse("quest complete 10")
      {:complete, "10"}

      iex> Game.Command.Channels.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("quest"), do: {:list, :active}
  def parse("quests"), do: {:list, :active}
  def parse("quest show " <> quest_id), do: {:show, quest_id}
  def parse("quest info " <> quest_id), do: {:show, quest_id}
  def parse("quest complete " <> quest_id), do: {:complete, quest_id}
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  Questing
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok | {:update, map}
  def run(command, session, state)
  def run({:list, :active}, _session, %{socket: socket, user: user}) do
    case Quest.for(user) do
      [] ->
        socket |> @socket.echo("You have no active quests.")
      quests ->
        socket |> @socket.echo(Format.quest_progress(quests))
    end
    :ok
  end

  def run({:show, quest_id}, _session, %{socket: socket, user: user, save: save}) do
    case Quest.progress_for(user, quest_id) do
      nil ->
        socket |> @socket.echo("You have not started this quest.")
      progress ->
        socket |> @socket.echo(Format.quest_detail(progress, save))
    end
    :ok
  end

  def run({:complete, quest_id}, _session, state = %{socket: socket, user: user}) do
    case Quest.progress_for(user, quest_id) do
      nil ->
        socket |> @socket.echo("You have not started this quest.")
        :ok
      progress ->
        progress
        |> gate_for_active(state)
        |> check_npc_is_in_room(state)
        |> check_steps_are_complete(state)
        |> complete_quest(state)
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
        state.socket |> @socket.echo("This quest is already complete.")
        :ok
    end
  end

  @doc """
  Check if the quest giver is in the same room
  """
  @spec check_npc_is_in_room(QuestProgress.t(), State.t()) :: :ok | QuestProgress.t()
  def check_npc_is_in_room(:ok, _state), do: :ok
  def check_npc_is_in_room(progress, %{socket: socket, save: save}) do
    npc_ids =
      save.room_id
      |> @room.look()
      |> Map.get(:npcs)
      |> Enum.map(&(Map.get(&1, :original_id)))

    case progress.quest.giver_id in npc_ids do
      true ->
        progress
      false ->
        socket |> @socket.echo("The quest giver #{Format.npc_name(progress.quest.giver)} cannot be found.")
        :ok
    end
  end

  @doc """
  Verify the quest is complete
  """
  @spec check_steps_are_complete(QuestProgress.t(), State.t()) :: :ok | QuestProgress.t()
  def check_steps_are_complete(:ok, _state), do: :ok
  def check_steps_are_complete(progress, state) do
    case Quest.requirements_complete?(progress, state.save) do
      true ->
        progress
      false ->
        response = Format.wrap_lines([
          "You have not completed the requirements for the quest.",
          "See {white}quest info #{progress.quest_id}{/white} for your current progress.",
        ])

        state.socket |> @socket.echo(response)
        :ok
    end
  end

  @spec complete_quest(QuestProgress.t(), State.t()) :: QuestProgress.t()
  def complete_quest(:ok, _state), do: :ok
  def complete_quest(progress, state = %{socket: socket, user: user, save: save}) do
    %{quest: quest} = progress

    case Quest.complete(progress, save) do
      {:ok, save} ->
        socket |> @socket.echo("Quest completed!")

        user = %{user | save: save}
        state = %{state | user: user, save: save}

        state = Experience.apply(state, level: quest.level, experience_points: quest.experience)

        {:update, state}
      _ ->
        socket |> @socket.echo("Something went wrong, please contact the administrators if you encounter a problem again.")
    end
  end
end
