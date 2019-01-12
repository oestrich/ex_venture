defmodule Game.Proficiency do
  @moduledoc """
  Functions for dealing with proficiencies
  """

  @doc """
  Checking a save matches the requirements
  """
  def check_requirements_met(save, requirements) do
    missing_requirements =
      Enum.reject(requirements, fn requirement ->
        requirement_satisifed?(requirement, save.proficiencies)
      end)

    case missing_requirements do
      [] ->
        :ok

      missing_requirements ->
        {:missing, missing_requirements}
    end
  end

  @doc """
  Check if a requirement is satisified from a list of instances
  """
  def requirement_satisifed?(requirement, instances) do
    Enum.any?(instances, fn instance ->
      instance.id == requirement.id && instance.ranks >= requirement.ranks
    end)
  end
end
