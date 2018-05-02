defmodule Web.Admin.QuestStepController do
  use Web.AdminController

  alias Web.Quest

  def new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => type}}) do
    quest = Quest.get(quest_id)
    changeset = Quest.new_step(quest)

    conn
    |> assign(:type, type)
    |> assign(:quest, quest)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def new(conn, %{"quest_id" => quest_id}) do
    new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => nil}})
  end

  def create(conn, %{"quest_id" => quest_id, "quest_step" => params}) do
    quest = Quest.get(quest_id)

    case Quest.create_step(quest, params) do
      {:ok, _step} ->
        conn
        |> put_flash(:info, "Step added for #{quest.name}")
        |> redirect(to: quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue adding the step. Please try again.")
        |> assign(:type, params["type"])
        |> assign(:quest, quest)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    step = Quest.get_step(id)
    changeset = Quest.edit_step(step)

    conn
    |> assign(:step, step)
    |> assign(:quest, step.quest)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "quest_step" => params}) do
    case Quest.update_step(id, params) do
      {:ok, step} ->
        conn
        |> put_flash(:info, "Step updated!")
        |> redirect(to: quest_path(conn, :show, step.quest_id))

      {:error, changeset} ->
        step = Quest.get_step(id)

        conn
        |> put_flash(:error, "There was an issue updating the step. Please try again.")
        |> assign(:step, step)
        |> assign(:quest, step.quest)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Quest.delete_step(id) do
      {:ok, step} ->
        conn
        |> put_flash(:info, "Step removed!")
        |> redirect(to: quest_path(conn, :show, step.quest_id))

      {:error, _changeset} ->
        step = Quest.get_step(id)

        conn
        |> put_flash(:error, "There was an issue removing the step. Please try again.")
        |> redirect(to: quest_path(conn, :show, step.quest_id))
    end
  end
end
