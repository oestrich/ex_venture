defmodule Data.StatsTest do
  use Data.ModelCase
  doctest Data.Stats

  alias Data.Stats

  describe "character stats" do
    setup do
      %{stats: base_stats()}
    end

    test "valid stats", %{stats: stats} do
      assert Stats.valid_character?(stats)
    end

    test "a field does not line up with it's type", %{stats: stats} do
      stats = %{stats | dexterity: :atom}
      refute Stats.valid_character?(stats)
    end
  end

  test "loading stats will cast keys" do
    {:ok, stats} = Stats.load(%{"slot" => "chest"})
    assert stats.slot == :chest
  end

  describe "defaults" do
    test "default move_points" do
      stats = Stats.default(%{})
      assert stats.move_points == 20
    end

    test "default max_move_points" do
      stats = Stats.default(%{})
      assert stats.max_move_points == 20
    end
  end
end
