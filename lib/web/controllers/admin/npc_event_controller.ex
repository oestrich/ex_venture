defmodule Web.Admin.NPCEventController do
  use Web.AdminController

  alias Web.NPC

  def index(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    conn
    |> assign(:npc, npc)
    |> render("index.html")
  end

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    conn
    |> assign(:npc, npc)
    |> assign(:field, "")
    |> render("new.html")
  end

  def create(conn, %{"npc_id" => npc_id, "event" => %{"body" => event}}) do
    npc = NPC.get(npc_id)

    case NPC.add_event(npc, event) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Event created!")
        |> redirect(to: npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating.")
        |> assign(:npc, npc)
        |> assign(:field, event)
        |> render("new.html")

      {:error, :invalid, changeset} ->
        conn
        |> assign(:npc, npc)
        |> assign(:field, event)
        |> assign(:errors, changeset.errors)
        |> render("new.html")
    end
  end

  def edit(conn, %{"npc_id" => npc_id, "id" => id}) do
    npc = NPC.get(npc_id)

    case Enum.find(npc.events, &(&1["id"] == id)) do
      nil ->
        conn |> redirect(to: npc_event_path(conn, :index, npc.id))

      event ->
        conn
        |> assign(:npc, npc)
        |> assign(:event, event)
        |> assign(:field, Poison.encode!(event, pretty: true))
        |> render("edit.html")
    end
  end

  def update(conn, %{"npc_id" => npc_id, "id" => id, "event" => %{"body" => body}}) do
    npc = NPC.get(npc_id)

    case Enum.find(npc.events, &(&1["id"] == id)) do
      nil ->
        conn |> redirect(to: npc_event_path(conn, :index, npc.id))

      event ->
        case NPC.edit_event(npc, id, body) do
          {:ok, _npc} ->
            conn
            |> put_flash(:info, "Event updated!")
            |> redirect(to: npc_event_path(conn, :index, npc.id))

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "There was a problem updating.")
            |> assign(:npc, npc)
            |> assign(:event, event)
            |> assign(:field, body)
            |> render("edit.html")

          {:error, :invalid, changeset} ->
            conn
            |> assign(:npc, npc)
            |> assign(:event, event)
            |> assign(:field, body)
            |> assign(:errors, changeset.errors)
            |> render("edit.html")
        end
    end
  end

  def delete(conn, %{"npc_id" => npc_id, "id" => id}) do
    npc = NPC.get(npc_id)

    case NPC.delete_event(npc, id) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Event removed!")
        |> redirect(to: npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem removing the event")
        |> redirect(to: npc_event_path(conn, :index, npc.id))
    end
  end

  def reload(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    case NPC.force_save_events(npc) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Events reloaded!")
        |> redirect(to: npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem reloading.")
        |> redirect(to: npc_event_path(conn, :index, npc.id))
    end
  end
end
