defmodule Web.AnnouncementView do
  use Web, :view

  alias Game.Config
  alias Web.Color
  alias Web.TimeView

  def render("title", assigns) do
    case assigns do
      %{announcement: announcement} ->
        announcement.title

      _ ->
        nil
    end
  end
end
