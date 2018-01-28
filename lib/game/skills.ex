defmodule Game.Skills do
  @moduledoc """
  GenServer to keep track of skills in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.Skill
  alias Data.Repo

  @ets_table :skills

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec skill(integer()) :: Skill.t() | nil
  def skill(instance = %Skill{}) do
    skill(instance.id)
  end

  def skill(id) when is_integer(id) do
    case :ets.lookup(@ets_table, id) do
      [{_, skill}] -> skill
      _ -> nil
    end
  end

  @spec skills([integer()]) :: [Skill.t()]
  def skills(ids) do
    ids
    |> Enum.map(&skill/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Insert a new skill into the loaded data
  """
  @spec insert(Skill.t()) :: :ok
  def insert(skill) do
    GenServer.call(__MODULE__, {:insert, skill})
  end

  @doc """
  Trigger an skill reload
  """
  @spec reload(Skill.t()) :: :ok
  def reload(skill), do: insert(skill)

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    create_table()
    GenServer.cast(self(), :load_skills)
    {:ok, %{}}
  end

  def handle_cast(:load_skills, state) do
    skills = Skill |> Repo.all()

    Enum.each(skills, fn skill ->
      :ets.insert(@ets_table, {skill.id, skill})
    end)

    {:noreply, state}
  end

  def handle_call({:insert, skill}, _from, state) do
    :ets.insert(@ets_table, {skill.id, skill})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(@ets_table)
    create_table()

    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_table, [:set, :protected, :named_table])
  end
end
