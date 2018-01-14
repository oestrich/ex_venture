defmodule Web.Admin.QuestStepController do
  use Web.AdminController

  alias Web.Quest

  def new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => type}}) do
    quest = Quest.get(quest_id)
    changeset = Quest.new_step(quest)
    conn |> render("new.html", type: type, quest: quest, changeset: changeset)
  end
  def new(conn, %{"quest_id" => quest_id}) do
    new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => nil}})
  end

  def create(conn, %{"quest_id" => quest_id, "quest_step" => params}) do
    quest = Quest.get(quest_id)
    case Quest.create_step(quest, params) do
      {:ok, _step} -> conn |> redirect(to: quest_path(conn, :show, quest.id))
      {:error, changeset} ->
        conn |> render("new.html", type: params["type"], quest: quest, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    step = Quest.get_step(id)
    changeset = Quest.edit_step(step)
    conn |> render("edit.html", step: step, quest: step.quest, changeset: changeset)
  end

  def update(conn, %{"id" => id, "quest_step" => params}) do
    case Quest.update_step(id, params) do
      {:ok, step} ->
        conn |> redirect(to: quest_path(conn, :show, step.quest_id))
      {:error, changeset} ->
        step = Quest.get_step(id)
        conn |> render("edit.html", quest: step.quest, step: step, changeset: changeset)
    end
  end
end
