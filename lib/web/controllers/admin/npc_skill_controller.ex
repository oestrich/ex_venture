defmodule Web.Admin.NPCSkillController do
  use Web.AdminController

  alias Web.Skill
  alias Web.NPC

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    conn |> render("new.html", skills: Skill.all(), npc: npc)
  end

  def create(conn, %{"npc_id" => npc_id, "skill" => %{"id" => skill_id}}) do
    npc = NPC.get(npc_id)

    case NPC.add_trainable_skill(npc, skill_id) do
      {:ok, npc} ->
        conn |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, _changeset} ->
        conn |> render("new.html", skills: Skill.all(), npc: npc)
    end
  end

  def delete(conn, %{"npc_id" => npc_id, "id" => skill_id}) do
    npc = NPC.get(npc_id)
    skill_id = String.to_integer(skill_id)

    case NPC.remove_trainable_skill(npc, skill_id) do
      {:ok, npc} ->
        conn |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, _changeset} ->
        conn |> redirect(to: npc_path(conn, :show, npc.id))
    end
  end
end
