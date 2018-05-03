defmodule Web.Admin.NoteController do
  use Web.AdminController

  alias Web.Note

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "note", %{})
    %{page: notes, pagination: pagination} = Note.all(filter: filter, page: page, per: per)

    conn
    |> assign(:notes, notes)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    note = Note.get(id)

    conn
    |> assign(:note, note)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Note.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"note" => params}) do
    case Note.create(params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "#{note.name} created!")
        |> redirect(to: note_path(conn, :show, note.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the note. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    note = Note.get(id)
    changeset = Note.edit(note)

    conn
    |> assign(:note, note)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "note" => params}) do
    case Note.update(id, params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "#{note.name} updated!")
        |> redirect(to: note_path(conn, :show, note.id))

      {:error, changeset} ->
        note = Note.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{note.name}. Please try again.")
        |> assign(:note, note)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
