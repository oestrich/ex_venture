defmodule Web.Admin.NPCSpawnerController do
  use Web.AdminController

  alias Web.NPC

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
end
