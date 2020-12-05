defmodule Kantele.Character.EmoteEvent do
  use Kalevala.Character.Event

  alias Kantele.Character.CommandView
  alias Kantele.Character.EmoteView

  def interested?(event) do
    event.data.type == "emote" && match?("rooms:" <> _, event.data.channel_name)
  end

  def echo(conn, event) do
    case event.from_pid == self() do
      true ->
        prompt(conn, CommandView, "prompt", %{})

      false ->
        conn
        |> assign(:character, event.data.character)
        |> assign(:text, event.data.text)
        |> render(EmoteView, "listen")
        |> prompt(CommandView, "prompt", %{})
    end
  end
end
