defmodule Game.Command.Hone do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

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
    - Dexterity
    - Constitution
    - Intelligence
    - Wisdom
    - Health Points
    - Skill Points

    It costs #{@hone_cost} expereince points. All stats are raised by #{@hone_stat_boost},
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
    state.socket |> @socket.echo(hone_help(state.save))
  end

  def run({:hone, stat}, state) do
    case parse_stat(stat) do
      {:error, :bad_stat} ->
        state.socket |> @socket.echo("\"#{stat}\" is not a stat you can hone.")

      {:ok, stat} ->
        state
        |> check_if_enough_experience_to_spend(stat)
        |> hone_stat(stat)
    end
  end

  @doc """
  Stats you can hone
  """
  def fields() do
    [
      :strength,
      :dexterity,
      :constitution,
      :intelligence,
      :wisdom,
      :health,
      :skill
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

    stat =
      Enum.find(fields(), fn field ->
        to_string(field) == stat
      end)

    case stat do
      nil -> {:error, :bad_stat}
      stat -> {:ok, stat}
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

    {command send='hone strength'}Strength{/command}
      Your strength is currently at #{save.stats.strength}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    {command send='hone dexterity'}Dexterity{/command}
      Your dexterity is currently at #{save.stats.dexterity}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    {command send='hone constitution'}Constitution{/command}
      Your constitution is currently at #{save.stats.constitution}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    {command send='hone intelligence'}Intelligence{/command}
      Your intelligence is currently at #{save.stats.intelligence}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    {command send='hone wisdom'}Wisdom{/command}
      Your wisdom is currently at #{save.stats.wisdom}, honing will add {yellow}#{@hone_stat_boost}{/yellow}
    {command send='hone health'}Health{/command} Points
      Your max health points are currently at #{save.stats.max_health_points}, honing will add {yellow}#{@hone_points_boost}{/yellow}
    {command send='hone skill'}Skill{/command} Points
      Your max skill points are currently at #{save.stats.max_skill_points}, honing will add {yellow}#{@hone_points_boost}{/yellow}

    Honing costs #{@hone_cost} xp. You have #{spendable_experience} xp left to spend.
    """
  end

  defp check_if_enough_experience_to_spend(state = %{save: save}, stat) do
    spendable_experience = save.experience_points - save.spent_experience_points

    case @hone_cost <= spendable_experience do
      true ->
        state

      false ->
        state.socket
        |> @socket.echo("You do not have enough experience to spend to hone #{stat}.")
    end
  end

  def hone_stat(:ok, _stat), do: :ok

  def hone_stat(state = %{user: user, save: save}, stat) do
    spent_experience_points = save.spent_experience_points + @hone_cost

    stats = raise_stat(save, stat)

    save = %{save | stats: stats, spent_experience_points: spent_experience_points}
    user = %{user | save: save}
    state = %{state | user: user, save: save}

    state.socket |> @socket.echo("You honed your #{stat}. It is now at #{stat_at(save, stat)}!")

    {:update, state}
  end

  def stat_at(save, :health) do
    Map.get(save.stats, :max_health_points)
  end

  def stat_at(save, :skill) do
    Map.get(save.stats, :max_skill_points)
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

  def raise_stat(save, stat) do
    save.stats |> Map.put(stat, stat_at(save, stat) + @hone_stat_boost)
  end
end
