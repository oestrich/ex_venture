defmodule Kantele.Character.SayEvent do
  use Kalevala.Character.Event

  alias Kantele.Character.CommandView
  alias Kantele.Character.SayAction
  alias Kantele.Character.SayView

  def interested?(event) do
    event.data.type == "speech" && match?("rooms:" <> _, event.data.channel_name)
  end

  def broadcast(conn, %{data: %{"at" => at, "at_character" => nil}}) do
    conn
    |> assign(:name, at)
    |> render(SayView, "character-not-found")
    |> prompt(CommandView, "prompt", %{})
  end

  def broadcast(conn, event) do
    params = Map.put(event.data, "channel_name", "rooms:#{conn.character.room_id}")

    conn
    |> SayAction.run(params)
    |> assign(:prompt, false)
  end

  def echo(conn, event) do
    conn
    |> assign(:character, event.data.character)
    |> assign(:id, event.data.id)
    |> assign(:text, event.data.text)
    |> assign(:meta, event.data.meta)
    |> render(SayView, say_view(event))
    |> prompt(CommandView, "prompt", %{})
  end

  defp say_view(event) do
    case event.from_pid == self() do
      true ->
        "echo"

      false ->
        "listen"
    end
  end

  def publish_error(conn, _error), do: conn
end
