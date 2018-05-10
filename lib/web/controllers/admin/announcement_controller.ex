defmodule Web.Admin.AnnouncementController do
  use Web.AdminController

  alias Web.Announcement

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: announcements, pagination: pagination} = Announcement.all(page: page, per: per)

    conn
    |> assign(:announcements, announcements)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    announcement = Announcement.get(id)

    conn
    |> assign(:announcement, announcement)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Announcement.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"announcement" => params}) do
    case Announcement.create(params) do
      {:ok, announcement} ->
        conn
        |> put_flash(:info, "#{announcement.title} created!")
        |> redirect(to: announcement_path(conn, :show, announcement.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the announcement. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    announcement = Announcement.get(id)
    changeset = Announcement.edit(announcement)

    conn
    |> assign(:announcement, announcement)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "announcement" => params}) do
    case Announcement.update(id, params) do
      {:ok, announcement} ->
        conn
        |> put_flash(:info, "#{announcement.title} updated!")
        |> redirect(to: announcement_path(conn, :show, announcement.id))

      {:error, changeset} ->
        announcement = Announcement.get(id)

        conn
        |> put_flash(
          :error,
          "There was a problem updating #{announcement.title}. Please try again."
        )
        |> assign(:announcement, announcement)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
