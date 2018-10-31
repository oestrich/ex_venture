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

      user = %{
        seconds_online: 61,
      }

      character = %{
        name: "hero",
        save: save,
        race: %{name: "Human"},
        class: %{name: "Fighter"},
      }

      %{user: user, character: character}
    end

    test "includes player name", %{user: user, character: character} do
      assert Regex.match?(~r/hero/, Players.info(user, character))
    end

    test "includes player race", %{user: user, character: character} do
      assert Regex.match?(~r/Human/, Players.info(user, character))
    end

    test "includes player class", %{user: user, character: character} do
      assert Regex.match?(~r/Fighter/, Players.info(user, character))
    end

    test "includes player level", %{user: user, character: character} do
      assert Regex.match?(~r/Level.+|.+1/, Players.info(user, character))
    end

    test "includes player xp", %{user: user, character: character} do
      assert Regex.match?(~r/XP.+|.+0/, Players.info(user, character))
    end

    test "includes player spent xp", %{user: user, character: character} do
      assert Regex.match?(~r/Spent XP.+|.+0/, Players.info(user, character))
    end

    test "includes player health", %{user: user, character: character} do
      assert Regex.match?(~r/Health.+|.+50\/55/, Players.info(user, character))
    end

    test "includes player skill points", %{user: user, character: character} do
      assert Regex.match?(~r/Skill Points.+|.+10\/10/, Players.info(user, character))
    end

    test "includes player endurance points", %{user: user, character: character} do
      assert Regex.match?(~r/Stamina.+|.+10\/10/, Players.info(user, character))
    end

    test "includes player strength", %{user: user, character: character} do
      assert Regex.match?(~r/Strength.+|.+10/, Players.info(user, character))
    end

    test "includes player agility", %{user: user, character: character} do
      assert Regex.match?(~r/Agility.+|.+10/, Players.info(user, character))
    end

    test "includes player intelligence", %{user: user, character: character} do
      assert Regex.match?(~r/Intelligence.+|.+10/, Players.info(user, character))
    end

    test "includes player awareness", %{user: user, character: character} do
      assert Regex.match?(~r/Awareness.+|.+10/, Players.info(user, character))
    end

    test "includes player vitality", %{user: user, character: character} do
      assert Regex.match?(~r/Vitality.+|.+10/, Players.info(user, character))
    end

    test "includes player willpower", %{user: user, character: character} do
      assert Regex.match?(~r/Willpower.+|.+10/, Players.info(user, character))
    end

    test "includes player play time", %{user: user, character: character} do
      assert Regex.match?(~r/Play Time.+|.+00h 01m 01s/, Players.info(user, character))
    end
  end
end
