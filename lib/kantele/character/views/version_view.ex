defmodule Kantele.Character.VersionView do
  use Kalevala.Character.View

  def render("show", %{kalevala_version: kalevala_version}) do
    ~i(Powered by Kalevala {color foreground="cyan"}v#{kalevala_version}{/color}.\n)
  end
end
