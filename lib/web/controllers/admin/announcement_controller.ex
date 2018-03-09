defmodule Web.Admin.AnnouncementController do
  use Web.AdminController

  alias Web.Announcement

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: announcements, pagination: pagination} = Announcement.all(page: page, per: per)
    conn |> render("index.html", announcements: announcements, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    announcement = Announcement.get(id)
    conn |> render("show.html", announcement: announcement)
  end

  def new(conn, _params) do
    changeset = Announcement.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"announcement" => params}) do
    case Announcement.create(params) do
      {:ok, announcement} ->
        conn |> redirect(to: announcement_path(conn, :show, announcement.id))

      {:error, changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    announcement = Announcement.get(id)
    changeset = Announcement.edit(announcement)
    conn |> render("edit.html", announcement: announcement, changeset: changeset)
  end

  def update(conn, %{"id" => id, "announcement" => params}) do
    case Announcement.update(id, params) do
      {:ok, announcement} ->
        conn |> redirect(to: announcement_path(conn, :show, announcement.id))

      {:error, changeset} ->
        announcement = Announcement.get(id)
        conn |> render("edit.html", announcement: announcement, changeset: changeset)
    end
  end
end
