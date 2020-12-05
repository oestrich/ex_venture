defmodule Kantele.Character.ChannelView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText
  alias Kantele.Character.CharacterView

  def render("name", %{name: name}) do
    ~i({color foreground="white"}[#{name}]{/color})
  end

  def render("echo", %{channel_name: channel_name, character: character, id: id, text: text}) do
    %EventText{
      topic: "Channel.Broadcast",
      data: %{
        channel_name: channel_name,
        character: character,
        id: id,
        text: text
      },
      text: [
        render("name", %{name: channel_name}),
        ~i( You say, ),
        ~i("{color foreground="green"}#{text}{/color}"\n)
      ]
    }
  end

  def render("listen", %{channel_name: channel_name, character: character, id: id, text: text}) do
    %EventText{
      topic: "Channel.Broadcast",
      data: %{
        channel_name: channel_name,
        character: character,
        id: id,
        text: text
      },
      text: [
        render("name", %{name: channel_name}),
        ~i( #{CharacterView.render("name", %{character: character})} says, ),
        ~i("{color foreground="green"}#{text}{/color}"\n)
      ]
    }
  end
end
