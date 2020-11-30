defmodule Kantele.Character.MoveCommand do
  use Kalevala.Character.Command

  def north(conn, _params) do
    conn
    |> request_movement("north")
    |> assign(:prompt, false)
  end

  def south(conn, _params) do
    conn
    |> request_movement("south")
    |> assign(:prompt, false)
  end

  def east(conn, _params) do
    conn
    |> request_movement("east")
    |> assign(:prompt, false)
  end

  def west(conn, _params) do
    conn
    |> request_movement("west")
    |> assign(:prompt, false)
  end

  def up(conn, _params) do
    conn
    |> request_movement("up")
    |> assign(:prompt, false)
  end

  def down(conn, _params) do
    conn
    |> request_movement("down")
    |> assign(:prompt, false)
  end
end
