defmodule Kantele.Character.WanderAction do
  @moduledoc """
  Action to pick a random exit and move
  """

  use Kalevala.Character.Action

  @impl true
  def run(conn, _data) do
    conn
    |> event("room/wander")
    |> assign(:prompt, false)
  end

  def publish_error(conn, _error), do: conn
end
