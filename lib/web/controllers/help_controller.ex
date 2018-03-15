defmodule Web.HelpController do
  use Web, :controller

  alias Web.HelpTopic

  def index(conn, _params) do
    help_topics = HelpTopic.all(alpha: true)
    conn |> render("index.html", help_topics: help_topics)
  end

  def show(conn, %{"id" => id}) do
    case HelpTopic.get(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      help_topic ->
        conn |> render("show.html", help_topic: help_topic)
    end
  end

  def commands(conn, _params) do
    commands = HelpTopic.commands()
    conn |> render("commands.html", commands: commands)
  end

  def command(conn, %{"command" => command}) do
    case HelpTopic.command(command) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      command ->
        conn |> render("command.html", command: command)
    end
  end

  def built_in(conn, %{"id" => id}) do
    case HelpTopic.built_in(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      built_in ->
        conn |> render("built_in.html", built_in: built_in)
    end
  end
end
