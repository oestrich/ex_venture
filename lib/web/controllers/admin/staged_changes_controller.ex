defmodule Web.Admin.StagedChangesController do
  use Web, :controller

  alias ExVenture.StagedChanges

  def index(conn, _params) do
    conn
    |> assign(:active_tab, :staged_changes)
    |> assign(:staged_changes, StagedChanges.changes())
    |> render("index.html")
  end

  def delete(conn, %{"id" => id, "type" => type}) do
    {:ok, staged_change} = StagedChanges.get(type, id)

    case StagedChanges.delete(staged_change) do
      {:ok, _staged_changes} ->
        conn
        |> put_flash(:info, "Change deleted")
        |> redirect(to: Routes.admin_staged_changes_path(conn, :index))
    end
  end

  def commit(conn, _params) do
    case StagedChanges.commit() do
      :ok ->
        conn
        |> put_flash(:info, "Changes committed!")
        |> redirect(to: Routes.admin_staged_changes_path(conn, :index))
    end
  end
end
