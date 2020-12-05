defmodule Kantele.Character.HelpCommand do
  use Kalevala.Character.Command

  alias Kalevala.Help
  alias Kantele.Character.HelpView

  def index(conn, _params) do
    render(conn, HelpView, "index")
  end

  def show(conn, %{"topic" => topic}) do
    case Help.get(topic) do
      {:ok, help_topic} ->
        conn
        |> assign(:help_topic, help_topic)
        |> render(HelpView, "show")

      {:error, :not_found} ->
        conn
        |> assign(:topic, topic)
        |> render(HelpView, "unknown")
    end
  end
end
