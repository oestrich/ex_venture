defmodule Web.Admin.QuestController do
  use Web.AdminController

  alias Web.Quest

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "quest", %{})
    %{page: quests, pagination: pagination} = Quest.all(filter: filter, page: page, per: per)

    conn
    |> assign(:quests, quests)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    quest = Quest.get(id)

    conn
    |> assign(:quest, quest)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Quest.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"quest" => params}) do
    case Quest.create(params) do
      {:ok, quest} ->
        conn
        |> put_flash(:info, "#{quest.name} created!")
        |> redirect(to: quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the quest. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    quest = Quest.get(id)
    changeset = Quest.edit(quest)

    conn
    |> assign(:quest, quest)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "quest" => params}) do
    case Quest.update(id, params) do
      {:ok, quest} ->
        conn
        |> put_flash(:info, "#{quest.name} updated!")
        |> redirect(to: quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        quest = Quest.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{quest.name}. Please try again.")
        |> assign(:quest, quest)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
