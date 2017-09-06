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
end
