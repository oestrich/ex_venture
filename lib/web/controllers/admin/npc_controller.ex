defmodule Web.Admin.NPCController do
  use Web.AdminController

  alias Web.NPC

  def index(conn, _params) do
    npcs = NPC.all()
    conn |> render("index.html", npcs: npcs)
  end

  def show(conn, %{"id" => id}) do
    npc = NPC.get(id)
    conn |> render("show.html", npc: npc)
  end

  def new(conn, _params) do
    changeset = NPC.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"npc" => params}) do
    case NPC.create(params) do
      {:ok, npc} -> conn |> redirect(to: npc_path(conn, :show, npc.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    npc = NPC.get(id)
    changeset = NPC.edit(npc)
    conn |> render("edit.html", npc: npc, changeset: changeset)
  end

  def update(conn, %{"id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} -> conn |> redirect(to: npc_path(conn, :show, npc.id))
      {:error, changeset} ->
        npc = NPC.get(id)
        conn |> render("edit.html", npc: npc, changeset: changeset)
    end
  end
end
