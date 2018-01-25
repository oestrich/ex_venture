defmodule Web.Admin.NoteController do
  use Web.AdminController

  alias Web.Note

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "note", %{})
    %{page: notes, pagination: pagination} = Note.all(filter: filter, page: page, per: per)
    conn |> render("index.html", notes: notes, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    note = Note.get(id)
    conn |> render("show.html", note: note)
  end

  def new(conn, _params) do
    changeset = Note.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"note" => params}) do
    case Note.create(params) do
      {:ok, note} -> conn |> redirect(to: note_path(conn, :show, note.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    note = Note.get(id)
    changeset = Note.edit(note)
    conn |> render("edit.html", note: note, changeset: changeset)
  end

  def update(conn, %{"id" => id, "note" => params}) do
    case Note.update(id, params) do
      {:ok, note} ->
        conn |> redirect(to: note_path(conn, :show, note.id))

      {:error, changeset} ->
        note = Note.get(id)
        conn |> render("edit.html", note: note, changeset: changeset)
    end
  end
end
