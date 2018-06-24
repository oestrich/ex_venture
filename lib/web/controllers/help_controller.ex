defmodule Web.HelpController do
  use Web, :controller

  alias Game.Help
  alias Web.HelpTopic

  def index(conn, _params) do
    help_topics = HelpTopic.all(alpha: true)

    conn
    |> assign(:help_topics, help_topics)
    |> render("index.html")
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

    conn
    |> assign(:commands, commands)
    |> render("commands.html")
  end

  def command(conn, %{"command" => command}) do
    with {:ok, command} <- HelpTopic.command(command),
         :ok <- check_user_allowed(conn, command) do
      conn
      |> assign(:command, command)
      |> render("command.html")
    else
      _ ->
        conn |> redirect(to: public_page_path(conn, :index))
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

  defp check_user_allowed(conn, command) do
    flags =
      conn.assigns
      |> Map.get(:user, %{})
      |> Map.get(:flags, [])

    case Help.allowed?(command, flags) do
      true ->
        :ok

      false ->
        {:error, :not_allowed}
    end
  end
end
