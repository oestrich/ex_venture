defmodule Web.Admin.SkillController do
  use Web.AdminController

  alias Web.Skill

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)
    conn |> render("show.html", skill: skill)
  end
end
