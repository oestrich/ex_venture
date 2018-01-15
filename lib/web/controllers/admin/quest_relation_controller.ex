defmodule Web.Admin.QuestRelationController do
  use Web.AdminController

  alias Web.Quest

  def new(conn, %{"quest_id" => quest_id, "side" => side}) do
    quest = Quest.get(quest_id)
    changeset = Quest.new_relation()
    conn |> render("new.html", quest: quest, side: side, changeset: changeset)
  end

  def create(conn, %{"quest_id" => quest_id, "side" => side, "quest_relation" => params}) do
    quest = Quest.get(quest_id)
    case Quest.create_relation(quest, side, params) do
      {:ok, _relation} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
      {:error, changeset} ->
        conn |> render("new.html", quest: quest, side: side, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id, "quest_id" => quest_id}) do
    quest = Quest.get(quest_id)
    case Quest.delete_relation(id) do
      {:ok, _relation} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
      {:error, _changeset} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
    end
  end
end
