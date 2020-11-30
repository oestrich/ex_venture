defmodule Kantele.Character.FleeAction do
  @moduledoc """
  Action to flee to a random exit in a room
  """

  use Kalevala.Character.Action

  @impl true
  def run(conn, _data) do
    conn
    |> event("room/flee")
    |> assign(:prompt, false)
  end

  def publish_error(conn, _error), do: conn
end
