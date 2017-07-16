defmodule Test.Game.Room do
  alias Data.Room

  def look(_id) do
    %Room{
      name: "Hallway",
      description: "An empty hallway",
      north_id: 10,
      west_id: 11,
    }
  end
end
