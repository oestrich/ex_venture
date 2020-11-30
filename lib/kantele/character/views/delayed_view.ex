defmodule Kantele.Character.DelayedView do
  use Kalevala.Character.View

  def render("display", %{command: command}) do
    ~s(Delayed command running: {color foreground="white"}#{command}{/color}\n)
  end
end
