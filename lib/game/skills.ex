defmodule Game.Skills do
  @moduledoc """
  GenServer to keep track of skills in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.Skill
  alias Data.Repo

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec skill(integer()) :: Skill.t() | nil
  def skill(instance = %Skill{}) do
    skill(instance.id)
  end

  def skill(id) when is_integer(id) do
    case Cachex.get(:skills, id) do
      {:ok, skill} when skill != nil -> skill
      _ -> nil
    end
  end

  def skill(command) when is_binary(command) do
    case Cachex.get(:skills, command) do
      {:ok, skill} when skill != nil -> skill
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
    GenServer.cast(self(), :load_skills)
    {:ok, %{}}
  end

  def handle_cast(:load_skills, state) do
    skills = Skill |> Repo.all()

    Enum.each(skills, fn skill ->
      Cachex.set(:skills, skill.id, skill)
      Cachex.set(:skills, skill.command, skill)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, skill}, _from, state) do
    Cachex.set(:skills, skill.id, skill)
    Cachex.set(:skills, skill.command, skill)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(:skills)

    {:reply, :ok, state}
  end
end
