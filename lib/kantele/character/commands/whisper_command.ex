defmodule Kantele.Character.WhisperCommand do
  use Kalevala.Character.Command

  def run(conn, params) do
    params = %{
      name: params["name"],
      text: params["text"]
    }

    conn
    |> event("whisper/send", params)
    |> assign(:prompt, false)
  end
end
