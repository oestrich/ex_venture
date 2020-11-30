defmodule Kantele.Character.WhisperEvent do
  use Kalevala.Character.Event

  require Logger

  alias Kantele.Character.CommandView
  alias Kantele.Character.WhisperView

  def interested?(event) do
    event.data.type == "whisper" && match?("rooms:" <> _, event.data.channel_name)
  end

  def broadcast(conn, %{data: %{character: character, text: text}}) when character != nil do
    options = [
      type: "whisper",
      meta: %{
        for: character
      }
    ]

    conn
    |> assign(:character, character)
    |> assign(:text, text)
    |> publish_message("rooms:#{conn.character.room_id}", text, options, &publish_error/2)
  end

  def broadcast(conn, event) do
    conn
    |> assign(:name, event.data.name)
    |> render(WhisperView, "character-not-found")
    |> prompt(CommandView, "prompt", %{})
  end

  def echo(conn, event) do
    conn
    |> assign(:whispering_character, event.acting_character)
    |> assign(:character, event.data.meta.for)
    |> assign(:id, event.data.id)
    |> assign(:text, event.data.text)
    |> render(WhisperView, whisper_view(conn, event))
    |> prompt(CommandView, "prompt", %{})
  end

  defp whisper_view(conn, event) do
    cond do
      conn.character.id == event.acting_character.id ->
        "echo"

      conn.character.id == event.data.meta.for.id ->
        "listen"

      true ->
        "obscured"
    end
  end

  def subscribe_error(conn, error) do
    Logger.error("Tried to subscribe to the new channel and failed - #{inspect(error)}")

    conn
  end

  def publish_error(conn, error) do
    Logger.error("Tried to publish to a channel and failed - #{inspect(error)}")

    conn
  end
end
