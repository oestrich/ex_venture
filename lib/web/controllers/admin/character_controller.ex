defmodule Web.Admin.CharacterController do
  use Web.AdminController

  alias Web.Character

  def show(conn, %{"id" => id}) do
    with {:ok, character} <- Character.get(id) do
      conn
      |> assign(:character, character)
      |> render("show.html")
    end
  end

  def watch(conn, %{"character_id" => id}) do
    {:ok, character} = Character.get(id)

    conn
    |> assign(:character, character)
    |> render("watch.html")
  end

  def reset(conn, %{"character_id" => id}) do
    Character.reset(id)

    redirect(conn, to: character_path(conn, :show, id))
  end

  def teleport(conn, %{"room_id" => room_id}) do
    %{current_character: character} = conn.assigns

    case Character.teleport(character, room_id) do
      {:ok, _character} ->
        conn |> redirect(to: room_path(conn, :show, room_id))

      _ ->
        conn |> redirect(to: room_path(conn, :show, room_id))
    end
  end

  def disconnect(conn, %{"character_id" => id}) do
    with {:ok, id} <- Ecto.Type.cast(:integer, id),
         :ok <- Character.disconnect(id) do
      conn |> redirect(to: character_path(conn, :show, id))
    else
      _ ->
        conn |> redirect(to: character_path(conn, :show, id))
    end
  end

  def disconnect(conn, _params) do
    Character.disconnect()
    conn |> redirect(to: dashboard_path(conn, :index))
  end
end
