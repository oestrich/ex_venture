defmodule Web.Admin.SkillController do
  use Web.AdminController

  alias Web.Skill

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "skill", %{})
    %{page: skills, pagination: pagination} = Skill.all(filter: filter, page: page, per: per)

    conn
    |> assign(:skills, skills)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)

    conn
    |> assign(:skill, skill)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Skill.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"skill" => params}) do
    case Skill.create(params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "#{skill.name} added!")
        |> redirect(to: skill_path(conn, :show, skill.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the skill. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
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
        |> put_flash(:info, "#{skill.name} updated!")
        |> redirect(to: skill_path(conn, :show, skill.id))

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
