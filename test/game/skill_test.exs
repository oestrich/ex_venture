defmodule Game.SkillTest do
  use ExUnit.Case
  doctest Game.Skill

  alias Game.Skill

  test "filtering out effects that don't match" do
    skill = %Data.Skill{whitelist_effects: ["damage"]}
    effects = [
      %{kind: "damage"},
      %{kind: "damage/over-time"},
    ]

    assert Skill.filter_effects(effects, skill) == [%{kind: "damage"}]
  end
end
