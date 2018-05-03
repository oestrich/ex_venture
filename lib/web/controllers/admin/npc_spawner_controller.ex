defmodule Web.Admin.NPCSpawnerController do
  use Web.AdminController

  alias Web.NPC
  alias Web.Zone

  def show(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    npc = NPC.get(npc_spawner.npc_id)

    conn
    |> assign(:npc_spawner, npc_spawner)
    |> assign(:npc, npc)
    |> render("show.html")
  end

  def new(conn, %{"npc_id" => npc_id, "npc_spawner" => %{"zone_id" => zone_id}}) do
    zone = Zone.get(zone_id)
    npc = NPC.get(npc_id)
    changeset = NPC.new_spawner(npc)

    conn
    |> assign(:npc, npc)
    |> assign(:changeset, changeset)
    |> assign(:zone, zone)
    |> render("new.html")
  end

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.new_spawner(npc)

    conn
    |> assign(:npc, npc)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"npc_id" => npc_id, "npc_spawner" => params}) do
    npc = NPC.get(npc_id)

    case NPC.add_spawner(npc, params) do
      {:ok, npc_spawner} ->
        conn
        |> put_flash(:info, "Spawner created!")
        |> redirect(to: npc_path(conn, :show, npc_spawner.npc_id))

      {:error, changeset} ->
        conn
        |> assign(:npc, npc)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    changeset = NPC.edit_spawner(npc_spawner)

    conn
    |> assign(:npc_spawner, npc_spawner)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "npc_spawner" => params}) do
    case NPC.update_spawner(id, params) do
      {:ok, npc_spawner} ->
        conn
        |> put_flash(:info, "Spawner updated!")
        |> redirect(to: npc_path(conn, :show, npc_spawner.npc_id))

      {:error, changeset} ->
        npc_spawner = NPC.get_spawner(id)

        conn
        |> put_flash(:error, "There was an issue updating the spawner. Please try again.")
        |> assign(:npc_spawner, npc_spawner)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id, "npc_id" => npc_id}) do
    case NPC.delete_spawner(id) do
      {:ok, _npc_spanwer} ->
        conn
        |> put_flash(:info, "NPC spawner deleted!")
        |> redirect(to: npc_path(conn, :show, npc_id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue deleting the spawner. Please try again.")
        |> redirect(to: npc_path(conn, :show, npc_id))
    end
  end
end
