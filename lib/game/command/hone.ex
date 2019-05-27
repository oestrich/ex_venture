defmodule Game.Command.Hone do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

  alias Game.Command.Hone.Proficiencies
  alias Game.Command.Hone.Stats
  alias Game.Format.Hone, as: FormatHone
  alias Game.Player
  alias Game.Proficiencies, as: GameProficiencies

  @hone_cost 300

  @hone_points_boost 5
  @hone_stat_boost 1

  commands(["hone"], parse: false)

  def hone_cost(), do: @hone_cost
  def hone_points_boost(), do: @hone_points_boost
  def hone_stat_boost(), do: @hone_stat_boost

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
    case parse_stat(stat) do
      {:error, :bad_stat} ->
        message = "\"#{stat}\" is not a stat you can hone."
        state |> Socket.echo(message)

      {:ok, :stat, stat} ->
        Stats.hone_stat(state, stat)

      {:ok, :proficiency, proficiency} ->
        Proficiencies.hone_proficiency(state, proficiency)
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
      Enum.find(GameProficiencies.all(), fn proficiency ->
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
    FormatHone.help(save, spendable_experience)
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

  defmodule Stats do
    @moduledoc """
    Hone a specific stat
    """

    alias Game.Command.Hone
    alias Game.Player

    @hone_points_boost 5
    @hone_stat_boost 1

    @doc """
    Hone a specific stat, if there is enough experience points
    """
    def hone_stat(state, stat) do
      with {:ok, state} <- Hone.spend_experience(state) do
        stats = raise_stat(state.save, stat)

        save = %{state.save | stats: stats}
        state = Player.update_save(state, save)

        Hone.send_stat_raised(state, stat, stat_at(save, stat))

        {:update, state}
      else
        {:error, :not_enough_experience} ->
          Hone.send_not_enough_experience(state, stat)
      end
    end

    def stat_at(save, :health) do
      Map.get(save.stats, :max_health_points)
    end

    def stat_at(save, :skill) do
      Map.get(save.stats, :max_skill_points)
    end

    def stat_at(save, :endurance) do
      Map.get(save.stats, :max_endurance_points)
    end

    def stat_at(save, stat) do
      Map.get(save.stats, stat)
    end

    def raise_stat(save, :health) do
      save.stats |> Map.put(:max_health_points, stat_at(save, :health) + @hone_points_boost)
    end

    def raise_stat(save, :skill) do
      save.stats |> Map.put(:max_skill_points, stat_at(save, :skill) + @hone_points_boost)
    end

    def raise_stat(save, :endurance) do
      save.stats |> Map.put(:max_endurance_points, stat_at(save, :endurance) + @hone_points_boost)
    end

    def raise_stat(save, stat) do
      save.stats |> Map.put(stat, stat_at(save, stat) + @hone_stat_boost)
    end
  end

  defmodule Proficiencies do
    @moduledoc """
    Hone a specific proficiency
    """

    alias Game.Command.Hone

    @doc """
    Hone a proficiency, if the player has the proficiency and enough experience
    """
    def hone_proficiency(state = %{save: save}, proficiency) do
      with {:ok, instance} <- find_proficiency_instance(save, proficiency),
           {:ok, state} <- Hone.spend_experience(state) do
        raise_proficiency(state, proficiency, instance)
      else
        {:error, :not_enough_experience} ->
          Hone.send_not_enough_experience(state, proficiency.name)

        {:error, :unknown} ->
          message = "You do not know #{proficiency.name}."
          state |> Socket.echo(message)
      end
    end

    def find_proficiency_instance(save, proficiency) do
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

    def raise_proficiency(state = %{save: save}, proficiency, instance) do
      instances = List.delete(save.proficiencies, instance)
      instance = Map.put(instance, :ranks, instance.ranks + 1)
      instances = [instance | instances]

      save = %{save | proficiencies: instances}
      state = Player.update_save(state, save)

      Hone.send_stat_raised(state, proficiency.name, instance.ranks)

      {:update, state}
    end
  end

  def send_stat_raised(state, name, value) do
    message = "You honed your #{name}. It is now at #{value}!"
    state |> Socket.echo(message)
  end

  def send_not_enough_experience(state, name) do
    message = "You do not have enough experience to spend to hone #{name}."
    state |> Socket.echo(message)
  end
end
