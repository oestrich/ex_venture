defmodule Web.Admin.QuestController do
  use Web.AdminController

  alias Web.Quest

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "quest", %{})
    %{page: quests, pagination: pagination} = Quest.all(filter: filter, page: page, per: per)
    conn |> render("index.html", quests: quests, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    quest = Quest.get(id)
    conn |> render("show.html", quest: quest)
  end

  def new(conn, _params) do
    changeset = Quest.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"quest" => params}) do
    case Quest.create(params) do
      {:ok, quest} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    quest = Quest.get(id)
    changeset = Quest.edit(quest)
    conn |> render("edit.html", quest: quest, changeset: changeset)
  end

  def update(conn, %{"id" => id, "quest" => params}) do
    case Quest.update(id, params) do
      {:ok, quest} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
      {:error, changeset} ->
        quest = Quest.get(id)
        conn |> render("edit.html", quest: quest, changeset: changeset)
    end
  end
end
