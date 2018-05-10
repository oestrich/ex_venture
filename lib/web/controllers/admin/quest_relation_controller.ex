defmodule Web.Admin.QuestRelationController do
  use Web.AdminController

  alias Web.Quest

  def new(conn, %{"quest_id" => quest_id, "side" => side}) do
    quest = Quest.get(quest_id)
    changeset = Quest.new_relation()

    conn
    |> assign(:quest, quest)
    |> assign(:side, side)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"quest_id" => quest_id, "side" => side, "quest_relation" => params}) do
    quest = Quest.get(quest_id)

    case Quest.create_relation(quest, side, params) do
      {:ok, _relation} ->
        conn
        |> put_flash(:info, "Quest chain updated for #{quest.name}!")
        |> redirect(to: quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        conn
        |> put_flash(
          :error,
          "There was a problem adding to the quest chain for #{quest.name}. Please try again."
        )
        |> assign(:quest, quest)
        |> assign(:side, side)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id, "quest_id" => quest_id}) do
    quest = Quest.get(quest_id)

    case Quest.delete_relation(id) do
      {:ok, _relation} ->
        conn
        |> put_flash(:info, "Quest chain updated for #{quest.name}")
        |> redirect(to: quest_path(conn, :show, quest.id))

      {:error, _changeset} ->
        conn
        |> put_flash(
          :error,
          "There was a problem updating the quest chain for #{quest.name}. Please try again."
        )
        |> redirect(to: quest_path(conn, :show, quest.id))
    end
  end
end
