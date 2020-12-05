defmodule Kantele.Character.TellEvent do
  use Kalevala.Character.Event

  require Logger

  alias Kantele.Character.CommandView
  alias Kantele.Character.TellView

  def interested?(event) do
    match?("characters:" <> _, event.data.channel_name)
  end

  def broadcast(conn, %{data: %{character: character, text: text}}) when character != nil do
    conn
    |> put_meta(:reply_to, character.name)
    |> assign(:character, character)
    |> assign(:text, text)
    |> render(TellView, "echo")
    |> prompt(CommandView, "prompt", %{})
    |> publish_message("characters:#{character.id}", text, [], &publish_error/2)
  end

  def broadcast(conn, event) do
    conn
    |> assign(:name, event.data.name)
    |> render(TellView, "character-not-found")
    |> prompt(CommandView, "prompt", %{})
  end

  def echo(conn, event) do
    conn
    |> assign(:character, event.data.character)
    |> assign(:id, event.data.id)
    |> assign(:text, event.data.text)
    |> render(TellView, "listen")
    |> prompt(CommandView, "prompt", %{})
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
