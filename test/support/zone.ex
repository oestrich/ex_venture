defmodule Test.Game.Zone do
  alias Data.Zone

  def start_link() do
    Agent.start_link(fn () -> %{zone: _zone()} end, name: __MODULE__)
  end

  def _zone() do
    %Zone{
      name: "Hallway",
    }
  end

  def map(_id, _player_at) do
    "    [ ]    \n[ ] [X] [ ]\n    [ ]    "
  end
end
