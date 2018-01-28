defmodule Web.Admin.SkillController do
  use Web.AdminController

  alias Web.Skill

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "skill", %{})
    %{page: skills, pagination: pagination} = Skill.all(filter: filter, page: page, per: per)
    conn |> render("index.html", skills: skills, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)
    conn |> render("show.html", skill: skill)
  end

  def new(conn, _params) do
    changeset = Skill.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"skill" => params}) do
    case Skill.create(params) do
      {:ok, skill} -> conn |> redirect(to: skill_path(conn, :show, skill.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    skill = Skill.get(id)
    changeset = Skill.edit(skill)
    conn |> render("edit.html", skill: skill, changeset: changeset)
  end

  def update(conn, %{"id" => id, "skill" => params}) do
    case Skill.update(id, params) do
      {:ok, skill} ->
        conn |> redirect(to: skill_path(conn, :show, skill.id))

      {:error, changeset} ->
        skill = Skill.get(id)
        conn |> render("edit.html", skill: skill, changeset: changeset)
    end
  end
end
