defmodule Kantele.Character.EmoteAction do
  @moduledoc """
  Action to emote in a channel (e.g. a room)
  """

  use Kalevala.Character.Action

  alias Kantele.Character.EmoteView

  @impl true
  def run(conn, params) do
    conn
    |> assign(:text, params["text"])
    |> render(EmoteView, "echo")
    |> publish_message(params["channel_name"], params["text"], [type: "emote"], &publish_error/2)
  end

  def publish_error(conn, _error), do: conn
end
