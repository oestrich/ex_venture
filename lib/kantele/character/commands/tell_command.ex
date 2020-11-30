defmodule Kantele.Character.TellCommand do
  use Kalevala.Character.Command

  def run(conn, params) do
    params = %{
      name: params["name"],
      text: params["text"]
    }

    conn
    |> event("tell/send", params)
    |> assign(:prompt, false)
  end
end
