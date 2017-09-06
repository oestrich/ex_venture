defmodule Data.SaveTest do
  use ExUnit.Case
  doctest Data.Save

  alias Data.Save

  test "ensures channels is always an array when loading" do
    {:ok, save} = Save.load(%{})
    assert save.channels == []
  end
end
