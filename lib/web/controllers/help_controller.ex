defmodule Web.HelpController do
  use Web, :controller

  alias Web.HelpTopic

  def index(conn, _params) do
    help_topics = HelpTopic.all(alpha: true)
    conn |> render("index.html", help_topics: help_topics)
  end

  def show(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    conn |> render("show.html", help_topic: help_topic)
  end

  def commands(conn, _params) do
    commands = HelpTopic.commands()
    conn |> render("commands.html", commands: commands)
  end

  def command(conn, %{"command" => command}) do
    command = HelpTopic.command(command)
    conn |> render("command.html", command: command)
  end

  def built_in(conn, %{"id" => id}) do
    built_in = HelpTopic.built_in(id)
    conn |> render("built_in.html", built_in: built_in)
  end
end
