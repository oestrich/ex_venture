defmodule Web.Admin.NPCItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.NPC

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.new_item(npc)
    conn |> render("new.html", items: Item.all(), npc: npc, changeset: changeset)
  end

  def create(conn, %{"npc_id" => npc_id, "item" => %{"id" => item_id}}) do
    npc = NPC.get(npc_id)
    case NPC.add_item(npc, item_id) do
      {:ok, npc} -> conn |> redirect(to: npc_path(conn, :show, npc.id))
      {:error, _changeset} -> conn |> render("add-item.html", items: Item.all(), npc: npc)
    end
  end

  def delete(conn, %{"npc_id" => npc_id, "id" => item_id}) do
    npc = NPC.get(npc_id)
    case NPC.delete_item(npc, item_id) do
      {:ok, npc} ->
        conn |> redirect(to: npc_path(conn, :show, npc.id))
      _ ->
        conn |> redirect(to: npc_path(conn, :show, npc.id))
    end
  end
end
