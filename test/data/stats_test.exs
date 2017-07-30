defmodule Data.StatsTest do
  use Data.ModelCase
  doctest Data.Stats

  alias Data.Stats

  test "loading stats will cast keys" do
    assert Stats.load(%{"slot" => "chest"}) == {:ok, %{slot: :chest}}
  end
end
