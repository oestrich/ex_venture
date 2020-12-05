defmodule Kantele.Character.SayView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText
  alias Kantele.Character.CharacterView

  def render("text", %{text: text}) do
    ~i("{text}#{text}{/text}")
  end

  def render("echo", %{text: text, meta: meta}) do
    %EventText{
      topic: "Room.Say",
      data: %{
        meta: meta,
        text: text
      },
      text: [
        "You say",
        render("_adverb", %{meta: meta}),
        render("_at", %{meta: meta}),
        ~i(, #{render("text", %{text: text})}\n)
      ]
    }
  end

  def render("listen", %{character: character, id: id, meta: meta, text: text}) do
    %EventText{
      topic: "Room.Say",
      data: %{
        character: character,
        id: id,
        meta: meta,
        text: text
      },
      text: [
        CharacterView.render("name", %{character: character}),
        " says",
        render("_adverb", %{meta: meta}),
        render("_at", %{meta: meta}),
        ~i(, #{render("text", %{text: text})}\n)
      ]
    }
  end

  def render("character-not-found", %{name: name}) do
    ~i(Character {color foreground="white"}#{name}{/color} could not be found.\n)
  end

  def render("_adverb", %{meta: %{adverb: adverb}}) do
    ~i( #{adverb})
  end

  def render("_adverb", _assigns), do: ""

  def render("_at", %{meta: %{at_character: at_character}}) do
    ~i( to #{CharacterView.render("name", %{character: at_character})})
  end

  def render("_at", _assigns), do: ""
end
