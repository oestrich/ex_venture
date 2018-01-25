defmodule Web.Admin.NPCSpawnerController do
  use Web.AdminController

  alias Web.NPC
  alias Web.Zone

  def show(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    npc = NPC.get(npc_spawner.npc_id)
    conn |> render("show.html", npc_spawner: npc_spawner, npc: npc)
  end

  def new(conn, %{"npc_id" => npc_id, "npc_spawner" => %{"zone_id" => zone_id}}) do
    zone = Zone.get(zone_id)
    npc = NPC.get(npc_id)
    changeset = NPC.new_spawner(npc)
    conn |> render("new.html", npc: npc, changeset: changeset, zone: zone)
  end

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.new_spawner(npc)
    conn |> render("new.html", npc: npc, changeset: changeset)
  end

  def create(conn, %{"npc_id" => npc_id, "npc_spawner" => params}) do
    npc = NPC.get(npc_id)

    case NPC.add_spawner(npc, params) do
      {:ok, npc_spawner} -> conn |> redirect(to: npc_path(conn, :show, npc_spawner.npc_id))
      {:error, changeset} -> conn |> render("new.html", npc: npc, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    changeset = NPC.edit_spawner(npc_spawner)
    conn |> render("edit.html", npc_spawner: npc_spawner, changeset: changeset)
  end

  def update(conn, %{"id" => id, "npc_spawner" => params}) do
    case NPC.update_spawner(id, params) do
      {:ok, npc_spawner} ->
        conn |> redirect(to: npc_path(conn, :show, npc_spawner.npc_id))

      {:error, changeset} ->
        npc_spawner = NPC.get_spawner(id)
        conn |> render("edit.html", npc_spawner: npc_spawner, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id, "npc_id" => npc_id}) do
    case NPC.delete_spawner(id) do
      {:ok, _npc_spanwer} -> conn |> redirect(to: npc_path(conn, :show, npc_id))
      {:error, _changeset} -> conn |> redirect(to: npc_path(conn, :show, npc_id))
    end
  end
end
