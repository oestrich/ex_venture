defmodule Web.Admin.NPCSkillController do
  use Web.AdminController

  alias Web.Skill
  alias Web.NPC

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    conn
    |> assign(:skills, Skill.all())
    |> assign(:npc, npc)
    |> render("new.html")
  end

  def create(conn, %{"npc_id" => npc_id, "skill" => %{"id" => skill_id}}) do
    npc = NPC.get(npc_id)

    case NPC.add_trainable_skill(npc, skill_id) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Skill added to #{npc.name}!")
        |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the skill. Please try again.")
        |> assign(:skills, Skill.all())
        |> assign(:npc, npc)
        |> render("new.html")
    end
  end

  def delete(conn, %{"npc_id" => npc_id, "id" => skill_id}) do
    npc = NPC.get(npc_id)
    skill_id = String.to_integer(skill_id)

    case NPC.remove_trainable_skill(npc, skill_id) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Skill removed!")
        |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem removing the skill. Please try again.")
        |> redirect(to: npc_path(conn, :show, npc.id))
    end
  end
end
