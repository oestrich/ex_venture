defmodule Web.AnnouncementController do
  use Web, :controller

  alias Web.Announcement

  def show(conn, %{"id" => id}) do
    case Announcement.get_by_uuid(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))
      announcement ->
        conn |> render("show.html", announcement: announcement)
    end
  end
end
