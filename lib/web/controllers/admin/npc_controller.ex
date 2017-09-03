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
end
