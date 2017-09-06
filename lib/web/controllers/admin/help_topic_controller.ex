defmodule Web.Admin.HelpTopicController do
  use Web.AdminController

  alias Web.HelpTopic

  def index(conn, _params) do
    help_topics = HelpTopic.all()
    conn |> render("index.html", help_topics: help_topics)
  end

  def show(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    conn |> render("show.html", help_topic: help_topic)
  end

  def new(conn, _params) do
    changeset = HelpTopic.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"help_topic" => params}) do
    case HelpTopic.create(params) do
      {:ok, help_topic} -> conn |> redirect(to: help_topic_path(conn, :show, help_topic.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    changeset = HelpTopic.edit(help_topic)
    conn |> render("edit.html", changeset: changeset, help_topic: help_topic)
  end

  def update(conn, %{"id" => id, "help_topic" => params}) do
    case HelpTopic.update(id, params) do
      {:ok, help_topic} -> conn |> redirect(to: help_topic_path(conn, :show, help_topic.id))
      {:error, changeset} ->
        help_topic = HelpTopic.get(id)
        conn |> render("edit.html", help_topic: help_topic, changeset: changeset)
    end
  end
end
