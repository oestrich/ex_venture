defmodule Web.AnnouncementController do
  use Web, :controller

  alias Web.Announcement

  def show(conn, %{"id" => id}) do
    announcement = Announcement.get(id)
    conn |> render("show.html", announcement: announcement)
  end
end
