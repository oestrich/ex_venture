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
end
