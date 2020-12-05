defmodule Kantele.Character.QuitView do
  use Kalevala.Character.View

  alias Kantele.Character.CharacterView

  # passed to foreman disconnect
  def render("disconnected", %{character: character}) do
    [
      CharacterView.render("name", %{character: character}),
      " has left the game."
    ]
  end

  def render("goodbye", _assigns) do
    "Goodbye!\n"
  end
end
