defmodule Kantele.Character.WhisperView do
  use Kalevala.Character.View

  alias Kantele.Character.CharacterView

  def render("echo", %{character: character, text: text}) do
    [
      "You whisper to ",
      CharacterView.render("name", %{character: character}),
      ~i(, {color foreground="green"}"#{text}"{/color}\n)
    ]
  end

  def render("listen", %{whispering_character: character, text: text}) do
    [
      CharacterView.render("name", %{character: character}),
      ~i( whispers to you, {color foreground="green"}"#{text}"{/color}\n)
    ]
  end

  def render("obscured", %{whispering_character: whispering_character, character: character}) do
    [
      CharacterView.render("name", %{character: whispering_character}),
      " whispers to ",
      CharacterView.render("name", %{character: character}),
      ".\n"
    ]
  end

  def render("character-not-found", %{name: name}) do
    ~i(Character {color foreground="white"}#{name}{/color} could not be found.\n)
  end
end
