defmodule Web.Admin.ZoneOverworldController do
  use Web.AdminController

  alias Web.Zone

  def exits(conn, %{"id" => id}) do
    zone = Zone.get(id)

    case Zone.overworld?(zone) do
      true ->
        conn
        |> assign(:zone, zone)
        |> render("exits.html")

      false ->
        conn
        |> put_flash(:error, "This zone does not have an overworld")
        |> redirect(to: zone_path(conn, :show, zone.id))
    end
  end

  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update_map(id, params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} updated!")
        |> redirect(to: zone_path(conn, :show, zone.id))

      {:error, _changeset} ->
        zone = Zone.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{zone.name}'s map. Please try again.")
        |> redirect(to: zone_path(conn, :show, zone.id))
    end
  end

  def create_exit(conn, %{"id" => id, "exit" => params}) do
    zone = Zone.get(id)

    case Zone.add_overworld_exit(zone, params) do
      {:ok, _zone, room_exit} ->
        conn
        |> put_status(201)
        |> render("exit.json", room_exit: room_exit)
    end
  end

  def delete_exit(conn, %{"id" => id, "exit_id" => exit_id}) do
    zone = Zone.get(id)

    case Zone.delete_overworld_exit(zone, exit_id) do
      {:ok, _zone} ->
        conn |> send_resp(204, "")
    end
  end
end
