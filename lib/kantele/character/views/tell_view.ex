defmodule Kantele.Character.TellView do
  use Kalevala.Character.View

  alias Kantele.Character.CharacterView

  def render("echo", %{character: character, text: text}) do
    [
      "You tell ",
      CharacterView.render("name", %{character: character}),
      ~i(, {color foreground="green"}"#{text}"{/color}\n)
    ]
  end

  def render("listen", %{character: character, text: text}) do
    [
      CharacterView.render("name", %{character: character}),
      ~i( tells you, {color foreground="green"}"#{text}"{/color}\n)
    ]
  end

  def render("character-not-found", %{name: name}) do
    ~i(Character {color foreground="white"}#{name}{/color} could not be found.\n)
  end
end
