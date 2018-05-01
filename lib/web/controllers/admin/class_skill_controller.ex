defmodule Web.Admin.ClassSkillController do
  use Web.AdminController

  alias Web.Class
  alias Web.Skill

  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Class.new_class_skill(class)
    skills = Skill.all()

    conn
    |> assign(:class, class)
    |> assign(:skills, skills)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"class_id" => class_id, "class_skill" => %{"skill_id" => skill_id}}) do
    class = Class.get(class_id)

    case Class.add_skill(class, skill_id) do
      {:ok, _class_skill} ->
        conn
        |> put_flash(:info, "Skill addeded to #{class.name}")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        skills = Skill.all()

        conn
        |> put_flash(:error, "There was an issue adding the skill")
        |> assign(:class, class)
        |> assign(:skills, skills)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Class.remove_skill(id) do
      {:ok, class_skill} ->
        conn
        |> put_flash(:info, "Skill removed")
        |> redirect(to: class_path(conn, :show, class_skill.class_id))

      _ ->
        conn
        |> put_flash(:error, "There was a problem removing the skill")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
