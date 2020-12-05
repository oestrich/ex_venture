defmodule Kantele.Character.ReplyView do
  use Kalevala.Character.View

  def render("missing-reply-to", _assigns) do
    ~i(You need to send a tell before you can reply!\n)
  end
end
