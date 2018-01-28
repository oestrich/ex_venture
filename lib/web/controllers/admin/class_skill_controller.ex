defmodule Web.Admin.ClassSkillController do
  use Web.AdminController

  alias Web.Class
  alias Web.Skill

  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Class.new_class_skill(class)
    skills = Skill.all()
    conn |> render("new.html", class: class, skills: skills, changeset: changeset)
  end

  def create(conn, %{"class_id" => class_id, "class_skill" => %{"skill_id" => skill_id}}) do
    class = Class.get(class_id)

    case Class.add_skill(class, skill_id) do
      {:ok, _class_skill} ->
        conn |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        skills = Skill.all()
        conn |> render("new.html", class: class, skills: skills, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Class.remove_skill(id) do
      {:ok, class_skill} ->
        conn |> redirect(to: class_path(conn, :show, class_skill.class_id))

      _ ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
