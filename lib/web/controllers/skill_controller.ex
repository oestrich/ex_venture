defmodule Web.SkillController do
  use Web, :controller

  alias Web.Skill

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: skills, pagination: pagination} = Skill.all(page: page, per: per)

    conn
    |> assign(:skills, skills)
    |> assign(:pagination, pagination)
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
