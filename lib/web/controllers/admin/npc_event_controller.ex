defmodule Web.Admin.NPCEventController do
  use Web.AdminController

  alias Web.NPC

  def index(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    conn |> render("index.html", npc: npc)
  end

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    conn |> render("new.html", npc: npc, field: "")
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
        |> render("new.html", npc: npc, field: event)
    end
  end

  def edit(conn, %{"npc_id" => npc_id, "id" => id}) do
    npc = NPC.get(npc_id)
    case Enum.find(npc.events, &(&1.id == id)) do
      nil ->
        conn |> redirect(to: npc_event_path(conn, :index, npc.id))

      event ->
        conn |> render("edit.html", npc: npc, event: event, field: Poison.encode!(event, pretty: true))
    end
  end

  def update(conn, %{"npc_id" => npc_id, "id" => id, "event" => %{"body" => body}}) do
    npc = NPC.get(npc_id)
    case Enum.find(npc.events, &(&1.id == id)) do
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
            |> render("edit.html", npc: npc, event: event, field: body)
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
