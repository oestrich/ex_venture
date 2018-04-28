defmodule Web.SkillController do
  use Web, :controller

  alias Web.Skill

  def index(conn, _params) do
    skills = Skill.all()
    conn
    |> assign(:skills, skills)
    |> render(:index)
  end

  def show(conn, %{"id" => id}) do
    case Skill.get(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      skill ->
        conn
        |> assign(:skill, skill)
        |> assign(:extended, true)
        |> render(:show)
    end
  end
end
