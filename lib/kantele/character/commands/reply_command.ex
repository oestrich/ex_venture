defmodule Kantele.Character.ReplyCommand do
  use Kalevala.Character.Command

  alias Kantele.Character.ReplyView

  def run(conn, params) do
    character = character(conn)

    reply_to(conn, character.meta.reply_to, params["text"])
  end

  defp reply_to(conn, character, _text) when is_nil(character) do
    render(conn, ReplyView, "missing-reply-to")
  end

  defp reply_to(conn, character, text) do
    params = %{
      name: character,
      text: text
    }

    conn
    |> event("tell/send", params)
    |> assign(:prompt, false)
  end
end
