defmodule Web.Skill do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Effect
  alias Data.Skill
  alias Data.Repo

  @doc """
  Get a skill
  """
  @spec get(id :: integer) :: Skill.t
  def get(id) do
    Skill |> Repo.get(id) |> Repo.preload([:class])
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(class :: Class.t) :: changeset :: map
  def new(class) do
    class
    |> Ecto.build_assoc(:skills)
    |> Skill.changeset(%{})
  end

  @doc """
  Create a skill
  """
  @spec create(class :: Class.t, params :: map) :: {:ok, Skill.t} | {:error, changeset :: map}
  def create(class, params) do
    class
    |> Ecto.build_assoc(:skills)
    |> Skill.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_effects()
  end

  defp parse_effects(params = %{"effects" => effects}) do
    case Poison.decode(effects) do
      {:ok, effects} -> effects |> cast_effects(params)
      _ -> params
    end
  end
  defp parse_effects(params), do: params

  defp cast_effects(effects, params) do
    effects = effects
    |> Enum.map(fn (effect) ->
      case Effect.load(effect) do
        {:ok, effect} -> effect
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)

    Map.put(params, "effects", effects)
  end
end
