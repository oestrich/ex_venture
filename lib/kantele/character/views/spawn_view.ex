defmodule Kantele.Character.SpawnView do
  use Kalevala.Character.View

  alias Kantele.Character.CharacterView

  def render("spawn", %{character: character}) do
    ~i(#{CharacterView.render("name", %{character: character})} spawned.)
  end
end
