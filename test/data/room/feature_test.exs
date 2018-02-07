defmodule Data.Room.FeatureTest do
  use Data.ModelCase
  doctest Data.Room.Feature

  alias Data.Room.Feature

  test "adds a uuid if one is not present" do
    assert {:ok, %{id: _}} = Feature.load(%{})
    assert {:ok, %{id: "id"}} = Feature.load(%{"id" => "id"})
  end
end
