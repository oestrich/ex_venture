defmodule Web.Admin.SkillEffectController do
  use Web.AdminController

  alias Web.Skill

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)

    conn
    |> assign(:skill, skill)
    |> render("show.html")
  end

  def edit(conn, %{"id" => id}) do
    skill = Skill.get(id)
    changeset = Skill.edit(skill)

    conn
    |> assign(:skill, skill)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "skill" => params}) do
    case Skill.update(id, params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "#{skill.name} effects updated!")
        |> redirect(to: skill_effect_path(conn, :show, skill.id))

      {:error, changeset} ->
        skill = Skill.get(id)

        conn
        |> put_flash(:error, "There was an issue update #{skill.name}. Please try again.")
        |> assign(:skill, skill)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
