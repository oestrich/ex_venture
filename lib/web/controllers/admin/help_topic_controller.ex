defmodule Web.Admin.HelpTopicController do
  use Web.AdminController

  alias Web.HelpTopic

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: help_topics, pagination: pagination} = HelpTopic.all(page: page, per: per)

    conn
    |> assign(:help_topics, help_topics)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)

    conn
    |> assign(:help_topic, help_topic)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = HelpTopic.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"help_topic" => params}) do
    case HelpTopic.create(params) do
      {:ok, help_topic} ->
        conn
        |> put_flash(:info, "#{help_topic.name} created!")
        |> redirect(to: help_topic_path(conn, :show, help_topic.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the help topic. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    changeset = HelpTopic.edit(help_topic)

    conn
    |> assign(:help_topic, help_topic)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "help_topic" => params}) do
    case HelpTopic.update(id, params) do
      {:ok, help_topic} ->
        conn
        |> put_flash(:info, "#{help_topic.name} updated!")
        |> redirect(to: help_topic_path(conn, :show, help_topic.id))

      {:error, changeset} ->
        help_topic = HelpTopic.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{help_topic.name}. Please try again.")
        |> assign(:help_topic, help_topic)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
