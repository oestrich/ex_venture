defmodule Game.Format.PlayersTest do
  use ExUnit.Case

  alias Game.Format.Players

  doctest Game.Format.Players

  describe "info formatting" do
    setup do
      stats = %{
        health_points: 50,
        max_health_points: 55,
        skill_points: 10,
        max_skill_points: 10,
        endurance_points: 10,
        max_endurance_points: 10,
        strength: 10,
        agility: 10,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      }

      save = %Data.Save{level: 1, experience_points: 0, spent_experience_points: 0, stats: stats}

      character = %{
        name: "hero",
        save: save,
        race: %{name: "Human"},
        class: %{name: "Fighter"},
        seconds_online: 61,
      }

      %{character: character}
    end

    test "includes player name", %{character: character} do
      assert Regex.match?(~r/hero/, Players.info(character))
    end

    test "includes player race", %{character: character} do
      assert Regex.match?(~r/Human/, Players.info(character))
    end

    test "includes player class", %{character: character} do
      assert Regex.match?(~r/Fighter/, Players.info(character))
    end

    test "includes player level", %{character: character} do
      assert Regex.match?(~r/Level.+|.+1/, Players.info(character))
    end

    test "includes player xp", %{character: character} do
      assert Regex.match?(~r/XP.+|.+0/, Players.info(character))
    end

    test "includes player spent xp", %{character: character} do
      assert Regex.match?(~r/Spent XP.+|.+0/, Players.info(character))
    end

    test "includes player health", %{character: character} do
      assert Regex.match?(~r/Health.+|.+50\/55/, Players.info(character))
    end

    test "includes player skill points", %{character: character} do
      assert Regex.match?(~r/Skill Points.+|.+10\/10/, Players.info(character))
    end

    test "includes player endurance points", %{character: character} do
      assert Regex.match?(~r/Stamina.+|.+10\/10/, Players.info(character))
    end

    test "includes player strength", %{character: character} do
      assert Regex.match?(~r/Strength.+|.+10/, Players.info(character))
    end

    test "includes player agility", %{character: character} do
      assert Regex.match?(~r/Agility.+|.+10/, Players.info(character))
    end

    test "includes player intelligence", %{character: character} do
      assert Regex.match?(~r/Intelligence.+|.+10/, Players.info(character))
    end

    test "includes player awareness", %{character: character} do
      assert Regex.match?(~r/Awareness.+|.+10/, Players.info(character))
    end

    test "includes player vitality", %{character: character} do
      assert Regex.match?(~r/Vitality.+|.+10/, Players.info(character))
    end

    test "includes player willpower", %{character: character} do
      assert Regex.match?(~r/Willpower.+|.+10/, Players.info(character))
    end

    test "includes player play time", %{character: character} do
      assert Regex.match?(~r/Play Time.+|.+00h 01m 01s/, Players.info(character))
    end
  end
end
