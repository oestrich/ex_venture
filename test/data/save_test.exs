defmodule Data.SaveTest do
  use ExUnit.Case

  alias Data.Save

  test "converting class back to an atom" do
    save = %Save{class: Game.Class.Fighter}
    {:ok, save} = Save.dump(save)
    {:ok, save} = save
    |> Poison.encode!()
    |> Poison.decode()
    {:ok, save} = Save.load(save)

    assert save.class == Game.Class.Fighter
  end
end
