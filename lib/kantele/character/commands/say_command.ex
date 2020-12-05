defmodule Kantele.Character.SayCommand do
  use Kalevala.Character.Command

  alias Kantele.Character.SayAction

  def run(conn, %{"at" => _at} = params) do
    conn
    |> event("say/send", params)
    |> assign(:prompt, false)
  end

  def run(conn, params) do
    params = Map.put(params, "channel_name", "rooms:#{conn.character.room_id}")

    conn
    |> SayAction.run(params)
    |> assign(:prompt, false)
  end
end
