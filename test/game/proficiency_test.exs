defmodule Game.ProficiencyTest do
  use ExUnit.Case

  alias Data.Proficiency.Instance
  alias Data.Proficiency.Requirement
  alias Game.Proficiency

  describe "checking requirements are satisfied" do
    test "all requirements met" do
      save = %{
        proficiencies: [
          %Instance{id: 1, ranks: 10}
        ]
      }

      requirements = [
        %Requirement{id: 1, ranks: 5}
      ]

      assert Proficiency.check_requirements_met(save, requirements) == :ok
    end

    test "some requirements are missing" do
      save = %{
        proficiencies: [
          %Instance{id: 1, ranks: 10}
        ]
      }

      requirements = [
        %Requirement{id: 1, ranks: 5},
        %Requirement{id: 2, ranks: 5}
      ]

      assert Proficiency.check_requirements_met(save, requirements) ==
        {:missing, [%Requirement{id: 2, ranks: 5}]}
    end

    test "none requirements met" do
      save = %{
        proficiencies: []
      }

      requirements = [
        %Requirement{id: 1, ranks: 5}
      ]

      assert Proficiency.check_requirements_met(save, requirements) ==
        {:missing, [%Requirement{id: 1, ranks: 5}]}
    end
  end
end
