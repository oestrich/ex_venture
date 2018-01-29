defmodule Web.SkillController do
  use Web, :controller

  alias Web.Skill

  def index(conn, _params) do
    skills = Skill.all()
    conn |> render("index.html", skills: skills)
  end

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)
    conn |> render("show.html", skill: skill)
  end
end
