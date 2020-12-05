defmodule Kantele.Character.ChannelCommand do
  use Kalevala.Character.Command

  def general(conn, params) do
    conn
    |> publish_message("general", params["text"], [], &publish_error/2)
    |> assign(:prompt, false)
  end

  def publish_error(conn, _error), do: conn
end
