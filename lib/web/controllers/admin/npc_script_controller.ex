defmodule Web.Admin.NPCScriptController do
  use Web.AdminController

  alias Web.NPC

  def show(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    conn
    |> assign(:npc, npc)
    |> render("show.html")
  end

  def edit(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.edit(npc)

    conn
    |> assign(:npc, npc)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"npc_id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Updated #{npc.name}!")
        |> redirect(to: npc_script_path(conn, :show, npc.id))

      {:error, changeset} ->
        npc = NPC.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{npc.name}. Please try again.")
        |> assign(:npc, npc)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
