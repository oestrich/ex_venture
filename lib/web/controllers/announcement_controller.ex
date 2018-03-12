defmodule Web.AnnouncementController do
  use Web, :controller

  alias Web.Announcement

  plug :fetch_announcement
  plug :check_published

  def show(conn, _params) do
    conn |> render("show.html")
  end

  defp fetch_announcement(conn, _opts) do
    case Announcement.get_by_uuid(conn.params["id"]) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index)) |> halt()
      announcement ->
        conn |> assign(:announcement, announcement)
    end
  end

  defp check_published(conn, _opts) do
    %{announcement: announcement} = conn.assigns
    case announcement.is_published do
      true ->
        conn
      false ->
        maybe_redirect_home(conn)
    end
  end

  def maybe_redirect_home(conn) do
    case conn.assigns do
      %{user: user} ->
        case "admin" in user.flags do
          true ->
            conn
          false ->
            conn |> redirect_home()
        end
      _ ->
        conn |> redirect_home()
    end
  end

  defp redirect_home(conn) do
    conn |> redirect(to: public_page_path(conn, :index)) |> halt()
  end
end
