defmodule Kantele.Character.MoveView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText
  alias Kantele.Character.CharacterView

  def render("enter", %{character: character}) do
    ~i(#{CharacterView.render("name", %{character: character})} enters.)
  end

  def render("leave", %{character: character}) do
    ~i(#{CharacterView.render("name", %{character: character})} leaves.)
  end

  def render("notice", %{character: character, direction: :to, reason: reason}) do
    %EventText{
      topic: "Room.CharacterEnter",
      data: %{character: character},
      text: [reason, "\n"]
    }
  end

  def render("notice", %{character: character, direction: :from, reason: reason}) do
    %EventText{
      topic: "Room.CharacterLeave",
      data: %{character: character},
      text: [reason, "\n"]
    }
  end

  def render("fail", %{reason: :no_exit, exit_name: exit_name}) do
    ~i(There is no exit #{exit_name}.\n)
  end
end
