defmodule Game.Command.Hone do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

  alias Game.Player
  alias Game.Proficiencies

  @hone_cost 300

  @hone_points_boost 5
  @hone_stat_boost 1

  commands(["hone"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Hone"
  def help(:short), do: "Hone your basic statistics"

  def help(:full) do
    """
    Honing lets you increase your basic stats:
    - Strength
    - Agility
    - Intelligence
    - Awareness
    - Vitality
    - Willpower
    - Health Points
    - Skill Points
    - Endurance Points

    It costs #{@hone_cost} experience points. All stats are raised by #{@hone_stat_boost},
    except health points and skill points which are raised by #{@hone_points_boost}.

    {command}hone{/command} by itself will show your current stats, what they will
    increase by, and how much you have to spend.

    To hone a stat, use {command}hone strength{/command} and replace "strength" with the
    stat you wish to hone.

    List out your current stats:
    [ ] > {command}hone{/command}

    Hone strength (or any other stat):
    [ ] > {command}hone strength{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Hone.parse("hone strength")
      {:hone, "strength"}

      iex> Game.Command.Hone.parse("hone")
      {:help}

      iex> Game.Command.Hone.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("hone"), do: {:help}
  def parse("hone " <> stat), do: {:hone, stat}

  @impl Game.Command
  @doc """
  Perform an emote
  """
  def run(command, state)

  def run({:help}, state) do
    state |> Socket.echo(hone_help(state.save))
  end

  def run({:hone, stat}, state) do
    # parse the stat, if it's a proficiency handle it separately

    case parse_stat(stat) do
      {:error, :bad_stat} ->
        message = gettext("\"%{stat}\" is not a stat you can hone.", stat: stat)
        state |> Socket.echo(message)

      {:ok, :stat, stat} ->
        hone_stat(state, stat)

      {:ok, :proficiency, proficiency} ->
        hone_proficiency(state, proficiency)
    end
  end

  @doc """
  Stats you can hone
  """
  def fields() do
    [
      :strength,
      :agility,
      :intelligence,
      :awareness,
      :vitality,
      :willpower,
      :health,
      :skill,
      :endurance
    ]
  end

  @doc """
  Parse a stat from the user
  """
  def parse_stat(stat) do
    stat =
      stat
      |> String.replace("points", "")
      |> String.trim()

    detected_stat =
      Enum.find(fields(), fn field ->
        to_string(field) == stat
      end)

    case detected_stat do
      nil ->
        parse_proficiency(stat)

      detected_stat ->
        {:ok, :stat, detected_stat}
    end
  end

  defp parse_proficiency(stat) do
    proficiency =
      Enum.find(Proficiencies.all(), fn proficiency ->
        String.downcase(proficiency.name) == String.downcase(stat)
      end)

    case proficiency do
      nil ->
        {:error, :bad_stat}

      proficiency ->
        {:ok, :proficiency, proficiency}
    end
  end

  @doc """
  List out hone help
  """
  @spec hone_help(Save.t()) :: String.t()
  def hone_help(save) do
    spendable_experience = save.experience_points - save.spent_experience_points

    """
    Which statistic do you want to hone?

    #{hone_field_help(save, :strength, "Strength")}
    #{hone_field_help(save, :agility, "Agility")}
    #{hone_field_help(save, :intelligence, "Intelligence")}
    #{hone_field_help(save, :awareness, "Awareness")}
    #{hone_field_help(save, :vitality, "Vitality")}
    #{hone_field_help(save, :willpower, "Willpower")}
    #{hone_points_help(save, :health, "Health")}
    #{hone_points_help(save, :skill, "Skill")}
    #{hone_points_help(save, :endurance, "Endurance")}

    Honing costs #{@hone_cost} xp. You have #{spendable_experience} xp left to spend.
    """
  end

  defp hone_field_help(save, field, title) do
    stat = Map.get(save.stats, field)

    String.trim("""
    {command send='hone #{field}'}#{title}{/command}
      Your #{field} is currently at #{stat}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    """)
  end

  defp hone_points_help(save, field, title) do
    stat = Map.get(save.stats, String.to_atom("max_#{field}_points"))

    boost = @hone_points_boost

    String.trim("""
    {command send='hone #{field}'}#{title}{/command} Points
      Your max #{field} points are currently at #{stat}, honing will add {yellow}#{boost}{/yellow}
    """)
  end

  @doc """
  Record the experience spend in the save

  If not enough experience available to spend, returns an error
  """
  def spend_experience(state = %{save: save}, hone_cost \\ @hone_cost) do
    spendable_experience = save.experience_points - save.spent_experience_points

    case hone_cost <= spendable_experience do
      true ->
        spent_experience_points = save.spent_experience_points + hone_cost
        save = %{save | spent_experience_points: spent_experience_points}
        state = Player.update_save(state, save)

        {:ok, state}

      false ->
        {:error, :not_enough_experience}
    end
  end

  @doc """
  Hone a specific stat, if there is enough experience points
  """
  def hone_stat(state, stat) do
    with {:ok, state} <- spend_experience(state) do
      stats = raise_stat(state.save, stat)

      save = %{state.save | stats: stats}
      state = Player.update_save(state, save)

      send_stat_raised(state, stat, stat_at(save, stat))

      {:update, state}
    else
      {:error, :not_enough_experience} ->
        send_not_enough_experience(state, stat)
    end
  end

  defp stat_at(save, :health) do
    Map.get(save.stats, :max_health_points)
  end

  defp stat_at(save, :skill) do
    Map.get(save.stats, :max_skill_points)
  end

  defp stat_at(save, :endurance) do
    Map.get(save.stats, :max_endurance_points)
  end

  defp stat_at(save, stat) do
    Map.get(save.stats, stat)
  end

  defp raise_stat(save, :health) do
    save.stats |> Map.put(:max_health_points, stat_at(save, :health) + @hone_points_boost)
  end

  defp raise_stat(save, :skill) do
    save.stats |> Map.put(:max_skill_points, stat_at(save, :skill) + @hone_points_boost)
  end

  defp raise_stat(save, :endurance) do
    save.stats |> Map.put(:max_endurance_points, stat_at(save, :endurance) + @hone_points_boost)
  end

  defp raise_stat(save, stat) do
    save.stats |> Map.put(stat, stat_at(save, stat) + @hone_stat_boost)
  end

  @doc """
  Hone a proficiency, if the player has the proficiency and enough experience
  """
  def hone_proficiency(state = %{save: save}, proficiency) do
    with {:ok, instance} <- find_proficiency_instance(save, proficiency),
         {:ok, state} <- spend_experience(state) do
      raise_proficiency(state, proficiency, instance)
    else
      {:error, :not_enough_experience} ->
        send_not_enough_experience(state, proficiency.name)

      {:error, :unknown} ->
        message =
          gettext("You do not know %{stat}.", stat: proficiency.name)

        state |> Socket.echo(message)
    end
  end

  defp find_proficiency_instance(save, proficiency) do
    instance =
      Enum.find(save.proficiencies, fn instance ->
        instance.id == proficiency.id
      end)

    case instance do
      nil ->
        {:error, :unknown}

      instance ->
        {:ok, instance}
    end
  end

  defp raise_proficiency(state = %{save: save}, proficiency, instance) do
    instances = List.delete(save.proficiencies, instance)
    instance = Map.put(instance, :ranks, instance.ranks + 1)
    instances = [instance | instances]

    save = %{save | proficiencies: instances}
    state = Player.update_save(state, save)

    send_stat_raised(state, proficiency.name, instance.ranks)

    {:update, state}
  end

  defp send_stat_raised(state, name, value) do
    message =
      gettext("You honed your %{name}. It is now at %{value}!", name: name, value: value)

    state |> Socket.echo(message)
  end

  defp send_not_enough_experience(state, name) do
    message =
      gettext("You do not have enough experience to spend to hone %{name}.", name: name)

    state |> Socket.echo(message)
  end
end
